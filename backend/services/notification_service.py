from firebase_admin import messaging
from typing import Optional, Dict, List
from datetime import datetime, timezone


class NotificationService:

    NOTIFICATION_TYPES = {
        "booking_hired": "booking",
        "agreement_pending": "booking",
        "agreement_signed": "booking",
        "payment_released": "payment",
        "application_accepted": "application",
        "application_declined": "application",
        "application_received": "application",
        "application_withdrawn": "application",
        "new_gig_match": "gig",
        "booking_confirmed": "booking",
        "booking_cancelled": "booking",
        "gig_reminder": "gig",
        "gig_created": "gig",
        "new_message": "message",
        "review_received": "system",
        "payment_received": "payment",
        "escrow_funded": "payment",
        "dispute_opened": "system",
        "system_broadcast": "system",
    }

    @staticmethod
    def _get_user_token(user_id: str) -> Optional[str]:
        from backend.database import db
        for collection in ["musicians", "organizers"]:
            doc = db.collection(collection).document(user_id).get()
            if doc.exists:
                return doc.to_dict().get("fcmToken")
        return None

    @staticmethod
    def _get_all_tokens(role: Optional[str] = None) -> List[Dict]:
        from backend.database import db
        tokens = []
        collections = ["musicians", "organizers"] if role is None else [role]
        for collection in collections:
            docs = db.collection(collection).where("fcmToken", "!=", "").get()
            for doc in docs:
                data = doc.to_dict()
                token = data.get("fcmToken")
                if token:
                    tokens.append({
                        "userId": doc.id,
                        "token": token,
                        "role": collection.rstrip("s"),
                    })
        return tokens

    @staticmethod
    def send_to_user(user_id: str, title: str, body: str, notif_type: str = "system", data: Optional[Dict[str, str]] = None):
        from backend.database import db

        token = NotificationService._get_user_token(user_id)
        if not token:
            print(f"No FCM token found for user: {user_id}")
            return None

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
            token=token,
        )

        try:
            response = messaging.send(message)
            NotificationService._save_notification(user_id, title, body, notif_type, data)
            print(f"Sent notification to {user_id}: {response}")
            return response
        except messaging.UnregisteredError:
            print(f"Stale token for {user_id}, removing")
            for collection in ["musicians", "organizers"]:
                doc_ref = db.collection(collection).document(user_id)
                if doc_ref.get().exists:
                    doc_ref.update({"fcmToken": None})
            return None
        except Exception as e:
            print(f"Error sending notification to {user_id}: {e}")
            return None

    @staticmethod
    def send_broadcast(title: str, body: str, audience: str, notif_type: str = "system_broadcast", data: Optional[Dict[str, str]] = None):
        from backend.database import db

        role_map = {
            "All Users": None,
            "Musicians": "musicians",
            "Organizers": "organizers",
        }
        role = role_map.get(audience)
        tokens_info = NotificationService._get_all_tokens(role)

        success = 0
        failed = 0

        for info in tokens_info:
            message = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=data or {},
                token=info["token"],
            )
            try:
                messaging.send(message)
                NotificationService._save_notification(info["userId"], title, body, notif_type, data)
                success += 1
            except messaging.UnregisteredError:
                db.collection(f"{info['role']}s").document(info["userId"]).update({"fcmToken": None})
                failed += 1
            except Exception:
                failed += 1

        NotificationService._save_broadcast_record(title, body, audience, success, failed)

        return {"success": success, "failed": failed, "total": len(tokens_info)}

    @staticmethod
    def _save_notification(user_id: str, title: str, body: str, notif_type: str, data: Optional[Dict] = None):
        from backend.database import db
        try:
            db.collection("notifications").add({
                "userId": user_id,
                "title": title,
                "body": body,
                "type": notif_type,
                "category": NotificationService.NOTIFICATION_TYPES.get(notif_type, "system"),
                "data": data or {},
                "isRead": False,
                "createdAt": datetime.now(timezone.utc),
            })
        except Exception as e:
            print(f"Error saving notification: {e}")

    @staticmethod
    def _save_broadcast_record(title: str, body: str, audience: str, success: int, failed: int):
        from backend.database import db
        try:
            db.collection("notification_broadcasts").add({
                "title": title,
                "body": body,
                "audience": audience,
                "recipients": success,
                "failed": failed,
                "status": "sent",
                "createdAt": datetime.now(timezone.utc),
            })
        except Exception as e:
            print(f"Error saving broadcast record: {e}")

    @staticmethod
    def get_user_notifications(user_id: str, limit: int = 50) -> List[Dict]:
        from backend.database import db
        try:
            docs = (db.collection("notifications")
                    .where("userId", "==", user_id)
                    .order_by("createdAt", direction="DESCENDING")
                    .limit(limit)
                    .get())
            return [{"id": doc.id, **doc.to_dict()} for doc in docs]
        except Exception as e:
            print(f"Error fetching notifications: {e}")
            return []

    @staticmethod
    def mark_read(notification_id: str) -> bool:
        from backend.database import db
        try:
            db.collection("notifications").document(notification_id).update({"isRead": True})
            return True
        except Exception as e:
            print(f"Error marking notification read: {e}")
            return False

    @staticmethod
    def mark_all_read(user_id: str) -> bool:
        from backend.database import db
        try:
            docs = db.collection("notifications").where("userId", "==", user_id).where("isRead", "==", False).get()
            batch = db.batch()
            for doc in docs:
                batch.update(doc.reference, {"isRead": True})
            batch.commit()
            return True
        except Exception as e:
            print(f"Error marking all read: {e}")
            return False

    @staticmethod
    def get_unread_count(user_id: str) -> int:
        from backend.database import db
        try:
            docs = db.collection("notifications").where("userId", "==", user_id).where("isRead", "==", False).get()
            return len(list(docs))
        except Exception:
            return 0

    @staticmethod
    def get_broadcast_history(limit: int = 50) -> List[Dict]:
        from backend.database import db
        try:
            docs = (db.collection("notification_broadcasts")
                    .order_by("createdAt", direction="DESCENDING")
                    .limit(limit)
                    .get())
            return [{"id": doc.id, **doc.to_dict()} for doc in docs]
        except Exception as e:
            print(f"Error fetching broadcast history: {e}")
            return []

    @staticmethod
    def register_fcm_token(user_id: str, role: str, token: str) -> bool:
        from backend.database import db
        collection = "musicians" if role == "musician" else "organizers"
        try:
            db.collection(collection).document(user_id).update({"fcmToken": token})
            return True
        except Exception as e:
            print(f"Error registering FCM token: {e}")
            return False
