from firebase_admin import firestore

from backend.database import db

class StripeWebhookHandler:
    @staticmethod
    def handle_event(event):
        event_type = event.get("type")
        data = event.get("data", {}).get("object", {})

        if event_type == "account.updated":
            StripeWebhookHandler._handle_account_updated(data)
        elif event_type == "payment_intent.succeeded":
            StripeWebhookHandler._handle_payment_intent_succeeded(data)
        elif event_type == "setup_intent.succeeded":
            StripeWebhookHandler._handle_setup_intent_succeeded(data)
        elif event_type == "charge.refunded":
            StripeWebhookHandler._handle_charge_refunded(data)
        elif event_type == "transfer.paid":
            StripeWebhookHandler._handle_transfer_paid(data)

    @staticmethod
    def _handle_account_updated(account_data):
        account_id = account_data.get("id")
        if not account_id:
            return

        # Search by stripe_connect_id (Express account) OR stripe_id
        musicians = db.collection("musicians").where("stripe_connect_id", "==", account_id).get()
        if not list(musicians):
            musicians = db.collection("musicians").where("stripe_id", "==", account_id).get()
        
        for musician in musicians:
            status = "active" if account_data.get("details_submitted") else "pending"
            update_data = {"stripe_status": status}
            # Also save the connect ID if not already set
            if not musician.to_dict().get("stripe_connect_id"):
                update_data["stripe_connect_id"] = account_id
            musician.reference.update(update_data)
            print(f"Updated musician {musician.id}: status={status}, connect_id={account_id}")

    @staticmethod
    def _handle_payment_intent_succeeded(payment_intent_data):
        booking_id = payment_intent_data.get("metadata", {}).get("booking_id")
        if not booking_id:
            return

        booking_ref = db.collection("bookings").document(booking_id)
        booking_ref.update({
            "payment_intent_status": "succeeded",
            "escrow_status": "held"
        })

    @staticmethod
    def _handle_setup_intent_succeeded(setup_intent_data):
        """Handle successful setup intent - save payment method to Firestore"""
        import stripe
        
        customer_id = setup_intent_data.get("customer")
        payment_method_id = setup_intent_data.get("payment_method")
        
        if not customer_id or not payment_method_id:
            return

        try:
            payment_method = stripe.PaymentMethod.retrieve(payment_method_id)
            
            # Search both organizers and musicians
            for collection in ["organizers", "musicians"]:
                users = db.collection(collection).where("stripe_id", "==", customer_id).get()
                for user in users:
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
                    db.collection(collection).document(user.id).collection("payment_methods").document(payment_method_id).set(payment_method_data)
                    print(f"Saved payment method {payment_method_id} for {collection}/{user.id}")
        except Exception as e:
            print(f"Error saving payment method: {str(e)}")

    @staticmethod
    def _handle_charge_refunded(charge_data):
        charge_id = charge_data.get("id")
        if not charge_id:
            return

        bookings = db.collection("bookings").where("charge_id", "==", charge_id).get()
        for booking in bookings:
            refunds_data = charge_data.get("refunds", {}).get("data", [])
            refund_id = refunds_data[0].get("id") if refunds_data else None
            booking.reference.update({"escrow_status": "refunded", "refund_id": refund_id})

    @staticmethod
    def _handle_transfer_paid(transfer_data):
        booking_id = transfer_data.get("metadata", {}).get("booking_id")
        if not booking_id:
            return

        booking_ref = db.collection("bookings").document(booking_id)
        booking_ref.update({"transfer_status": "paid"})
