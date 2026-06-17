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
        elif event_type == "charge.refunded":
            StripeWebhookHandler._handle_charge_refunded(data)
        elif event_type == "transfer.paid":
            StripeWebhookHandler._handle_transfer_paid(data)

    @staticmethod
    def _handle_account_updated(account_data):
        account_id = account_data.get("id")
        if not account_id:
            return

        musicians = db.collection("musicians").where("stripe_id", "==", account_id).get()
        for musician in musicians:
            status = "active" if account_data.get("details_submitted") else "pending"
            musician.reference.update({"stripe_status": status})

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
    def _handle_charge_refunded(charge_data):
        charge_id = charge_data.get("id")
        if not charge_id:
            return

        bookings = db.collection("bookings").where("charge_id", "==", charge_id).get()
        for booking in bookings:
            booking.reference.update({"escrow_status": "refunded", "refund_id": charge_data.get("refunds", {}).get("data", [])[0].get("id") if charge_data.get("refunds", {}).get("data") else None})

    @staticmethod
    def _handle_transfer_paid(transfer_data):
        booking_id = transfer_data.get("metadata", {}).get("booking_id")
        if not booking_id:
            return

        booking_ref = db.collection("bookings").document(booking_id)
        booking_ref.update({"transfer_status": "paid"})
