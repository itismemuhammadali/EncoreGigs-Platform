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
        if musician.get("stripe_id"):
            return musician["stripe_id"]

        email = musician.get("email") or f"{musician_id}@onlygigz.local"
        account = stripe.Account.create(
            type="express",
            country="US",
            email=email,
            capabilities={"transfers": {"requested": True}},
            metadata={"musicianId": musician_id}
        )

        status = "pending"
        if account.get("details_submitted"):
            status = "active"

        musician_ref.update({
            "stripe_id": account.id,
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
        organizer_ref = db.collection("organizers").document(organizer_id)
        organizer_doc = organizer_ref.get()
        if not organizer_doc.exists:
            raise ValueError(f"Organizer {organizer_id} not found")

        organizer = organizer_doc.to_dict()
        if organizer.get("stripe_id"):
            return organizer["stripe_id"]

        email = organizer.get("email") or f"{organizer_id}@onlygigz.local"
        customer = stripe.Customer.create(
            email=email,
            metadata={"organizerId": organizer_id}
        )
        organizer_ref.update({"stripe_id": customer.id})
        return customer.id

    @staticmethod
    def deposit_to_escrow(booking_id: str, organizer_id: str, amount: float, payment_method_id: str, currency: str = "usd"):
        StripeManager._assert_api_key()
        if amount <= 0:
            raise ValueError("Deposit amount must be greater than zero")

        customer_id = StripeManager.create_organizer_customer(organizer_id)
        try:
            stripe.PaymentMethod.attach(payment_method_id, customer=customer_id)
        except stripe.error.InvalidRequestError:
            # Payment method may already be attached to the customer.
            pass

        stripe.Customer.modify(
            customer_id,
            invoice_settings={"default_payment_method": payment_method_id}
        )

        payment_intent = stripe.PaymentIntent.create(
            amount=int(amount * 100),
            currency=currency,
            customer=customer_id,
            payment_method=payment_method_id,
            off_session=True,
            confirm=True,
            metadata={"booking_id": booking_id, "organizer_id": organizer_id},
            description=f"OnlyGigz Escrow deposit for booking {booking_id}",
            transfer_group=f"booking_{booking_id}"
        )

        update_data = {
            "charge_id": None,
            "payment_intent_id": payment_intent.id,
            "escrow_status": "held",
            "escrow_amount": amount,
            "currency": currency
        }

        if payment_intent.charges.data:
            update_data["charge_id"] = payment_intent.charges.data[0].id

        db.collection("bookings").document(booking_id).update(update_data)
        return payment_intent

    @staticmethod
    def release_booking_payment(booking_id: str, currency: str = "usd"):
        StripeManager._assert_api_key()
        booking_ref = db.collection("bookings").document(booking_id)
        booking_doc = booking_ref.get()
        if not booking_doc.exists:
            raise ValueError(f"Booking {booking_id} not found")

        booking = booking_doc.to_dict()
        musician_id = booking.get("musicianId")
        amount = float(booking.get("amount", 0))
        if amount <= 0:
            raise ValueError("Booking amount is not valid for release")

        musician_ref = db.collection("musicians").document(musician_id)
        musician_doc = musician_ref.get()
        if not musician_doc.exists:
            raise ValueError(f"Musician {musician_id} not found")

        musician = musician_doc.to_dict()
        connected_account_id = musician.get("stripe_id")
        if not connected_account_id:
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
            raise ValueError("STRIPE_WEBHOOK_SECRET is required for webhook verification")
        return stripe.Webhook.construct_event(payload=payload, sig_header=sig_header, secret=webhook_secret)
