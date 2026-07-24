from firebase_admin import firestore
from datetime import datetime, timezone
from typing import Optional


MILESTONE_THRESHOLDS = {
    "musician": [10, 100, 1000, 5000, 10000, 50000, 100000],
    "organizer": [10, 100, 1000, 5000, 10000],
    "gig": [10, 100, 1000, 5000, 10000],
    "revenue": [100, 1000, 5000, 10000, 50000, 100000],
}


class AdminNotificationService:

    @staticmethod
    def _save(title: str, body: str, category: str, data: Optional[dict] = None):
        from backend.database import db
        try:
            db.collection("admin_notifications").add({
                "title": title,
                "body": body,
                "category": category,
                "data": data or {},
                "isRead": False,
                "createdAt": datetime.now(timezone.utc),
            })
        except Exception as e:
            print(f"Error saving admin notification: {e}")

    @staticmethod
    def _milestone_already_reached(key: str, threshold: int) -> bool:
        from backend.database import db
        try:
            doc = db.collection("admin_milestones_reached").document(f"{key}_{threshold}").get()
            return doc.exists
        except Exception:
            return False

    @staticmethod
    def _mark_milestone_reached(key: str, threshold: int):
        from backend.database import db
        try:
            db.collection("admin_milestones_reached").document(f"{key}_{threshold}").set({
                "key": key,
                "threshold": threshold,
                "reachedAt": datetime.now(timezone.utc),
            })
        except Exception:
            pass

    @staticmethod
    def check_milestones():
        from backend.database import db

        counts = {}
        for collection, key in [("musicians", "musician"), ("organizers", "organizer")]:
            docs = db.collection(collection).get()
            counts[key] = len(list(docs))

        gig_docs = db.collection("gigs").get()
        counts["gig"] = len(list(gig_docs))

        booking_docs = db.collection("bookings").get()
        total_revenue = 0
        for doc in booking_docs:
            data = doc.to_dict()
            amount = data.get("amount", 0)
            if isinstance(amount, (int, float)):
                total_revenue += amount
        counts["revenue"] = total_revenue

        for key, thresholds in MILESTONE_THRESHOLDS.items():
            current = counts.get(key, 0)
            for threshold in thresholds:
                if current >= threshold and not AdminNotificationService._milestone_already_reached(key, threshold):
                    label_map = {
                        "musician": "musicians",
                        "organizer": "organizers",
                        "gig": "gigs posted",
                        "revenue": "in bookings",
                    }
                    if key == "revenue":
                        title = f"Revenue milestone: ${threshold:,} reached!"
                        body = f"The platform has processed ${threshold:,} in total bookings."
                    else:
                        title = f"Milestone: {threshold:,} {label_map[key]} registered!"
                        body = f"The platform now has {threshold:,} {label_map[key]}."

                    AdminNotificationService._save(title, body, "milestone", {"key": key, "threshold": threshold})
                    AdminNotificationService._mark_milestone_reached(key, threshold)

    @staticmethod
    def security_alert(title: str, body: str, ip: Optional[str] = None):
        AdminNotificationService._save(title, body, "security", {"ip": ip} if ip else {})

    @staticmethod
    def user_activity(title: str, body: str, data: Optional[dict] = None):
        AdminNotificationService._save(title, body, "user_activity", data or {})

    @staticmethod
    def payment_alert(title: str, body: str, data: Optional[dict] = None):
        AdminNotificationService._save(title, body, "payment", data or {})

    @staticmethod
    def platform_health(title: str, body: str, data: Optional[dict] = None):
        AdminNotificationService._save(title, body, "health", data or {})

    @staticmethod
    def get_notifications(limit: int = 50) -> list:
        from backend.database import db
        try:
            docs = (db.collection("admin_notifications")
                    .order_by("createdAt", direction="DESCENDING")
                    .limit(limit)
                    .get())
            return [{"id": doc.id, **doc.to_dict()} for doc in docs]
        except Exception as e:
            print(f"Error fetching admin notifications: {e}")
            return []

    @staticmethod
    def get_unread_count() -> int:
        from backend.database import db
        try:
            docs = db.collection("admin_notifications").where("isRead", "==", False).get()
            return len(list(docs))
        except Exception:
            return 0

    @staticmethod
    def mark_read(notification_id: str) -> bool:
        from backend.database import db
        try:
            db.collection("admin_notifications").document(notification_id).update({"isRead": True})
            return True
        except Exception:
            return False

    @staticmethod
    def mark_all_read() -> bool:
        from backend.database import db
        try:
            docs = db.collection("admin_notifications").where("isRead", "==", False).get()
            batch = db.batch()
            for doc in docs:
                batch.update(doc.reference, {"isRead": True})
            batch.commit()
            return True
        except Exception:
            return False
