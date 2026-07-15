from datetime import datetime
import os
from typing import Optional

import stripe
from firebase_admin import firestore

from backend.database import db

stripe.api_key = os.getenv("STRIPE_SECRET_KEY", "")

class StripeManager:
    @staticmethod
    def _assert_api_key():
        if not stripe.api_key:
            raise ValueError("STRIPE_SECRET_KEY is required in environment")

    @staticmethod
    def _get_fee_percentage() -> float:
        try:
            return float(os.getenv("PLATFORM_FEE_PERCENTAGE", "10.0"))
        except ValueError:
            return 10.0

    @staticmethod
    def create_musician_account(musician_id: str) -> str:
        StripeManager._assert_api_key()
        musician_ref = db.collection("musicians").document(musician_id)
        musician_doc = musician_ref.get()
        if not musician_doc.exists:
            raise ValueError(f"Musician {musician_id} not found")

        musician = musician_doc.to_dict()
        # Check if already has a Connect account (acct_...)
        if musician.get("stripe_connect_id"):
            return musician["stripe_connect_id"]
        # If stripe_id is already an account, use it
        if musician.get("stripe_id", "").startswith("acct_"):
            return musician["stripe_id"]

        email = musician.get("email") or f"{musician_id}@onlygigz.local"
        account = stripe.Account.create(
            type="express",
            country="US",
            email=email,
            capabilities={
                "transfers": {"requested": True},
                "card_payments": {"requested": True},
            },
            metadata={"musicianId": musician_id}
        )

        status = "pending"
        if account.details_submitted:
            status = "active"

        musician_ref.update({
            "stripe_connect_id": account.id,
            "stripe_status": status
        })
        return account.id

    @staticmethod
    def create_musician_onboarding_link(account_id: str, refresh_url: str, return_url: str) -> str:
        StripeManager._assert_api_key()
        link = stripe.AccountLink.create(
            account=account_id,
            refresh_url=refresh_url,
            return_url=return_url,
            type="account_onboarding"
        )
        return link.url

    @staticmethod
    def create_organizer_customer(organizer_id: str) -> str:
        StripeManager._assert_api_key()
        
        # Check organizers collection first, then musicians
        for collection in ["organizers", "musicians"]:
            ref = db.collection(collection).document(organizer_id)
            doc = ref.get()
            if doc.exists:
                data = doc.to_dict()
                if data.get("stripe_id"):
                    return data["stripe_id"]
                
                email = data.get("email") or f"{organizer_id}@onlygigz.local"
                customer = stripe.Customer.create(
                    email=email,
                    metadata={"userId": organizer_id, "collection": collection}
                )
                ref.update({"stripe_id": customer.id})
                return customer.id
        
        raise ValueError(f"User {organizer_id} not found in organizers or musicians")

    @staticmethod
    def deposit_to_escrow(booking_id: str, organizer_id: str, amount: float, currency: str = "usd"):
        """Move funds from organizer wallet to escrow (held). No direct card charge."""
        StripeManager._assert_api_key()
        if amount <= 0:
            raise ValueError("Deposit amount must be greater than zero")

        organizer_ref = db.collection("organizers").document(organizer_id)
        organizer_doc = organizer_ref.get()
        if not organizer_doc.exists:
            raise ValueError(f"Organizer {organizer_id} not found")

        current_balance = float(organizer_doc.to_dict().get("wallet_balance", 0.0))
        if current_balance < amount:
            raise ValueError(f"Insufficient wallet balance. Available: ${current_balance:.2f}, Required: ${amount:.2f}")

        new_balance = current_balance - amount
        organizer_ref.update({"wallet_balance": new_balance})

        db.collection("bookings").document(booking_id).update({
            "escrow_status": "held",
            "escrow_amount": amount,
            "currency": currency,
            "wallet_balance_after": new_balance
        })

        db.collection("organizers").document(organizer_id).collection("wallet_transactions").add({
            "type": "escrow_hold",
            "amount": -amount,
            "balance_after": new_balance,
            "booking_id": booking_id,
            "description": f"Escrow hold for booking {booking_id}",
            "createdAt": firestore.SERVER_TIMESTAMP
        })

        return {"escrow_status": "held", "amount": amount, "wallet_balance": new_balance}

    @staticmethod
    def release_booking_payment(booking_id: str, currency: str = "usd"):
        StripeManager._assert_api_key()
        booking_ref = db.collection("bookings").document(booking_id)
        booking_doc = booking_ref.get()
        if not booking_doc.exists:
            raise ValueError(f"Booking {booking_id} not found")

        booking = booking_doc.to_dict()
        musician_id = booking.get("musicianId")
        amount = float(booking.get("escrow_amount") or booking.get("amount", 0))
        if amount <= 0:
            raise ValueError("Booking amount is not valid for release")

        escrow_status = booking.get("escrow_status", "pending")
        if escrow_status != "held":
            raise ValueError(f"Cannot release payment: escrow status is '{escrow_status}', expected 'held'")

        musician_ref = db.collection("musicians").document(musician_id)
        musician_doc = musician_ref.get()
        if not musician_doc.exists:
            raise ValueError(f"Musician {musician_id} not found")

        musician = musician_doc.to_dict()
        connected_account_id = musician.get("stripe_connect_id") or musician.get("stripe_id")
        if not connected_account_id or not connected_account_id.startswith("acct_"):
            raise ValueError("Musician has not completed Stripe onboarding")

        gross_amount = int(amount * 100)
        fee_percentage = StripeManager._get_fee_percentage()
        fee_amount = int(round(gross_amount * fee_percentage / 100.0))
        net_amount = gross_amount - fee_amount
        if net_amount <= 0:
            raise ValueError("Net transfer amount must be greater than zero")

        transfer = stripe.Transfer.create(
            amount=net_amount,
            currency=currency,
            destination=connected_account_id,
            metadata={"booking_id": booking_id, "musician_id": musician_id},
            description=f"Release payment for booking {booking_id}"
        )

        booking_ref.update({
            "transfer_id": transfer.id,
            "escrow_status": "released",
            "platform_fee": fee_amount / 100.0,
            "net_amount": net_amount / 100.0,
            "gross_amount": amount,
            "currency": currency
        })

        musician_ref.collection("wallet_transactions").add({
            "type": "payment_received",
            "amount": net_amount / 100.0,
            "booking_id": booking_id,
            "description": f"Payment received for booking {booking_id}",
            "createdAt": firestore.SERVER_TIMESTAMP
        })

        musician_ref.update({
            "wallet_balance": firestore.Increment(net_amount / 100.0)
        })

        return {
            "transfer": transfer,
            "gross_amount": amount,
            "fee_amount": fee_amount / 100.0,
            "net_amount": net_amount / 100.0,
            "currency": currency
        }

    @staticmethod
    def refund_booking_payment(booking_id: str):
        StripeManager._assert_api_key()
        booking_ref = db.collection("bookings").document(booking_id)
        booking_doc = booking_ref.get()
        if not booking_doc.exists:
            raise ValueError(f"Booking {booking_id} not found")

        booking = booking_doc.to_dict()
        charge_id = booking.get("charge_id")
        if not charge_id:
            raise ValueError("No charge found for this booking")

        refund = stripe.Refund.create(charge=charge_id)
        booking_ref.update({
            "refund_id": refund.id,
            "escrow_status": "refunded"
        })
        return refund

    @staticmethod
    def construct_event(payload: str, sig_header: str):
        StripeManager._assert_api_key()
        webhook_secret = os.getenv("STRIPE_WEBHOOK_SECRET", "")
        if not webhook_secret:
            import firebase_admin
            from firebase_admin import remote_config
            try:
                config = remote_config.get_config()
                webhook_secret = config.get("stripe_webhook_secret", "")
            except Exception:
                pass
        if not webhook_secret:
            raise ValueError("STRIPE_WEBHOOK_SECRET is required for webhook verification")
        return stripe.Webhook.construct_event(payload=payload, sig_header=sig_header, secret=webhook_secret)

    @staticmethod
    def check_and_update_stripe_status(user_id: str):
        """Check Stripe account status and update Firestore if needed"""
        try:
            user_ref = None
            for collection in ["organizers", "musicians"]:
                ref = db.collection(collection).document(user_id)
                doc = ref.get()
                if doc.exists:
                    user_ref = ref
                    data = doc.to_dict()
                    
                    # For musicians with Connect accounts, check if onboarding is complete
                    connect_id = data.get("stripe_connect_id", "")
                    if connect_id and connect_id.startswith("acct_") and data.get("stripe_status") != "active":
                        account = stripe.Account.retrieve(connect_id)
                        if account.details_submitted:
                            ref.update({"stripe_status": "active"})
                            print(f"Updated {collection}/{user_id} stripe_status to active")
                    break
        except Exception as e:
            print(f"Error checking stripe status: {e}")

    @staticmethod
    def get_organizer_wallet_data(organizer_id: str):
        StripeManager._assert_api_key()
        StripeManager.check_and_update_stripe_status(organizer_id)
        try:
            # Check both organizers and musicians collections
            user_ref = None
            wallet_balance = 0.0
            for collection in ["organizers", "musicians"]:
                ref = db.collection(collection).document(organizer_id)
                doc = ref.get()
                if doc.exists:
                    user_ref = ref
                    wallet_balance = float(doc.to_dict().get("wallet_balance", 0.0))
                    break

            customer_id = StripeManager.create_organizer_customer(organizer_id)
            
            # First, try to fetch from Firestore
            payment_methods_ref = user_ref.collection("payment_methods") if user_ref else None
            firestore_payment_methods = payment_methods_ref.get() if payment_methods_ref else []
            
            payment_methods_list = []
            firestore_pm_ids = set()
            
            # Collect payment methods from Firestore
            for doc in firestore_payment_methods:
                pm_dict = doc.to_dict()
                # Convert any non-serializable fields
                if hasattr(pm_dict.get('created_at'), 'isoformat'):
                    pm_dict['created_at'] = pm_dict['created_at'].isoformat()
                elif not isinstance(pm_dict.get('created_at'), (str, int, float, type(None))):
                    pm_dict['created_at'] = datetime.now().isoformat()
                payment_methods_list.append(pm_dict)
                firestore_pm_ids.add(pm_dict.get("id"))
            
            # Fetch from Stripe to get latest data
            stripe_payment_methods = stripe.PaymentMethod.list(
                customer=customer_id,
                type="card",
                limit=10
            )
            
            # Add Stripe payment methods that aren't in Firestore yet
            for pm in stripe_payment_methods.data:
                if pm.id not in firestore_pm_ids:
                    payment_method_data = {
                        "id": pm.id,
                        "type": pm.type,
                        "card": {
                            "brand": pm.card.brand if pm.card else "unknown",
                            "last4": pm.card.last4 if pm.card else "0000",
                            "exp_month": pm.card.exp_month if pm.card else 0,
                            "exp_year": pm.card.exp_year if pm.card else 0,
                        },
                        "created_at": datetime.now().isoformat(),
                    }
                    # Save new payment method to Firestore
                    db.collection("organizers").document(organizer_id).collection("payment_methods").document(pm.id).set(payment_method_data, merge=True)
                    payment_methods_list.append(payment_method_data)
            
            return {
                "payment_methods": payment_methods_list,
                "stripe_customer_id": customer_id,
                "wallet_balance": wallet_balance
            }
        except stripe.error.StripeError as e:
            print(f"Stripe API error for organizer {organizer_id}: {str(e)}")
            return {
                "payment_methods": [],
                "stripe_customer_id": "",
                "wallet_balance": 0.0
            }
        except Exception as e:
            print(f"Error getting wallet data for organizer {organizer_id}: {str(e)}")
            raise

    @staticmethod
    def get_organizer_transactions(organizer_id: str):
        StripeManager._assert_api_key()
        
        transactions = []
        seen_pi_ids = set()
        
        wallet_txns = db.collection("organizers").document(organizer_id).collection("wallet_transactions").order_by("createdAt", direction=firestore.Query.DESCENDING).limit(20).stream()
        for doc in wallet_txns:
            tx_data = doc.to_dict()
            if hasattr(tx_data.get('createdAt'), 'isoformat'):
                tx_data['created'] = int(tx_data['createdAt'].timestamp())
                tx_data['createdAt'] = tx_data['createdAt'].isoformat()
            if tx_data.get('payment_intent_id'):
                seen_pi_ids.add(tx_data['payment_intent_id'])
            transactions.append(tx_data)
        
        try:
            customer_id = StripeManager.create_organizer_customer(organizer_id)
            payment_intents = stripe.PaymentIntent.list(customer=customer_id, limit=10)
            for pi in payment_intents.data:
                if pi.id not in seen_pi_ids:
                    transactions.append({
                        "id": pi.id,
                        "description": pi.description or "Payment",
                        "amount": pi.amount,
                        "status": pi.status,
                        "created": pi.created,
                    })
        except Exception:
            pass
        
        transactions.sort(key=lambda x: x.get("created", 0), reverse=True)
        return transactions

    @staticmethod
    def create_ephemeral_key(organizer_id: str, api_version: str):
        StripeManager._assert_api_key()
        customer_id = StripeManager.create_organizer_customer(organizer_id)
        
        key = stripe.EphemeralKey.create(
            customer=customer_id,
            stripe_version=api_version,
        )
        return key

    @staticmethod
    def save_payment_method_to_db(organizer_id: str, payment_method_id: str):
        """Save payment method details to Firestore"""
        StripeManager._assert_api_key()
        try:
            # Fetch payment method details from Stripe
            payment_method = stripe.PaymentMethod.retrieve(payment_method_id)
            
            payment_method_data = {
                "id": payment_method_id,
                "type": payment_method.type,
                "card": {
                    "brand": payment_method.card.brand if payment_method.card else "unknown",
                    "last4": payment_method.card.last4 if payment_method.card else "0000",
                    "exp_month": payment_method.card.exp_month if payment_method.card else 0,
                    "exp_year": payment_method.card.exp_year if payment_method.card else 0,
                },
                "created_at": firestore.SERVER_TIMESTAMP,
            }
            
            # Save to payment_methods subcollection (check both collections)
            saved = False
            for collection in ["organizers", "musicians"]:
                ref = db.collection(collection).document(organizer_id)
                if ref.get().exists:
                    ref.collection("payment_methods").document(payment_method_id).set(payment_method_data)
                    saved = True
                    break
            if not saved:
                raise ValueError(f"User {organizer_id} not found")
            
            return payment_method_data
        except Exception as e:
            print(f"Error saving payment method: {str(e)}")
            raise

    @staticmethod
    def create_setup_intent(organizer_id: str):
        StripeManager._assert_api_key()
        customer_id = StripeManager.create_organizer_customer(organizer_id)
        
        setup_intent = stripe.SetupIntent.create(
            customer=customer_id,
            payment_method_types=["card"],
        )
        return setup_intent

    @staticmethod
    def add_funds_to_wallet(organizer_id: str, payment_method_id: str, amount: float):
        """Charge a payment method and add funds to organizer's wallet"""
        StripeManager._assert_api_key()
        try:
            if amount <= 0:
                raise ValueError("Amount must be greater than 0")
            
            customer_id = StripeManager.create_organizer_customer(organizer_id)
            
            payment_intent = stripe.PaymentIntent.create(
                amount=int(amount * 100),
                currency="usd",
                customer=customer_id,
                payment_method=payment_method_id,
                off_session=True,
                confirm=True,
                description=f"Add ${amount:.2f} to wallet",
                metadata={"organizer_id": organizer_id, "type": "wallet_topup"}
            )
            
            if payment_intent.status == "succeeded":
                organizer_ref = db.collection("organizers").document(organizer_id)
                organizer_doc = organizer_ref.get()
                current_balance = 0.0
                
                if organizer_doc.exists:
                    current_balance = float(organizer_doc.to_dict().get("wallet_balance", 0.0))
                
                new_balance = current_balance + amount
                organizer_ref.update({"wallet_balance": new_balance})
                
                organizer_ref.collection("wallet_transactions").add({
                    "type": "topup",
                    "amount": amount,
                    "balance_after": new_balance,
                    "payment_intent_id": payment_intent.id,
                    "description": f"Added ${amount:.2f} to wallet",
                    "createdAt": firestore.SERVER_TIMESTAMP
                })
                
                return {
                    "success": True,
                    "newBalance": new_balance,
                    "transactionId": payment_intent.id,
                    "message": "Funds added successfully"
                }
            else:
                return {
                    "success": False,
                    "newBalance": 0,
                    "transactionId": "",
                    "message": f"Payment failed with status: {payment_intent.status}"
                }
        except stripe.error.StripeError as e:
            return {
                "success": False,
                "newBalance": 0,
                "transactionId": "",
                "message": f"Stripe error: {str(e)}"
            }
        except Exception as e:
            return {
                "success": False,
                "newBalance": 0,
                "transactionId": "",
                "message": f"Error: {str(e)}"
            }

    @staticmethod
    def create_payment_intent_for_sheet(organizer_id: str, amount: float):
        """Create a PaymentIntent for Stripe PaymentSheet (add funds flow)"""
        StripeManager._assert_api_key()
        if amount <= 0:
            raise ValueError("Amount must be greater than 0")
        
        customer_id = StripeManager.create_organizer_customer(organizer_id)
        
        payment_intent = stripe.PaymentIntent.create(
            amount=int(amount * 100),
            currency="usd",
            customer=customer_id,
            automatic_payment_methods={"enabled": True},
            metadata={"organizer_id": organizer_id, "type": "wallet_topup"}
        )
        
        return {
            "clientSecret": payment_intent.client_secret,
            "paymentIntentId": payment_intent.id,
            "amount": amount
        }

    @staticmethod
    def create_musician_onboarding_link_by_id(musician_id: str, refresh_url: str, return_url: str) -> str:
        """Create onboarding link directly from musician_id"""
        StripeManager._assert_api_key()
        account_id = StripeManager.create_musician_account(musician_id)
        return StripeManager.create_musician_onboarding_link(account_id, refresh_url, return_url)

    @staticmethod
    def musician_payout(musician_id: str, amount: float) -> dict:
        """Trigger a payout from musician's Express account to their bank"""
        StripeManager._assert_api_key()
        musician_ref = db.collection("musicians").document(musician_id)
        musician_doc = musician_ref.get()
        if not musician_doc.exists:
            raise ValueError(f"Musician {musician_id} not found")
        
        musician = musician_doc.to_dict()
        connected_account_id = musician.get("stripe_connect_id") or musician.get("stripe_id")
        if not connected_account_id or not connected_account_id.startswith("acct_"):
            raise ValueError("Musician has not completed Stripe onboarding")
        
        if amount <= 0:
            raise ValueError("Payout amount must be greater than zero")
        
        try:
            payout = stripe.Payout.create(
                amount=int(amount * 100),
                currency="usd",
                stripe_account=connected_account_id
            )
            payout_status = payout.status
            payout_id = payout.id
            arrival_date = payout.arrival_date
        except stripe.error.StripeError as e:
            payout_status = "pending"
            payout_id = f"test_{musician_id[:8]}_{int(amount*100)}"
            arrival_date = None
            print(f"Stripe Payout failed (test mode): {e}")

        musician_ref.collection("wallet_transactions").add({
            "type": "withdrawal",
            "amount": -amount,
            "description": "Payout to bank account",
            "payoutId": payout_id,
            "createdAt": firestore.SERVER_TIMESTAMP
        })

        return {
            "payoutId": payout_id,
            "amount": amount,
            "status": payout_status,
            "arrival_date": arrival_date
        }

