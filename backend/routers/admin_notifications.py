from typing import Any
from fastapi import APIRouter, HTTPException
from backend.services.admin_notification_service import AdminNotificationService

router = APIRouter(prefix="/admin/notifications", tags=["admin-notifications"])


@router.get("")
async def get_notifications(limit: int = 50):
    return AdminNotificationService.get_notifications(limit)


@router.get("/unread-count")
async def get_unread_count():
    return {"count": AdminNotificationService.get_unread_count()}


@router.patch("/{notification_id}/read")
async def mark_read(notification_id: str):
    success = AdminNotificationService.mark_read(notification_id)
    if not success:
        raise HTTPException(status_code=500, detail="Failed to mark as read")
    return {"message": "Marked as read"}


@router.post("/read-all")
async def mark_all_read():
    success = AdminNotificationService.mark_all_read()
    if not success:
        raise HTTPException(status_code=500, detail="Failed to mark all as read")
    return {"message": "All marked as read"}


@router.post("/check-milestones")
async def check_milestones():
    AdminNotificationService.check_milestones()
    return {"message": "Milestones checked"}


@router.get("/preferences")
async def get_notification_preferences():
    try:
        from backend.database import db
        doc: Any = db.collection("system_config").document("notification_preferences").get()
        if doc.exists:
            data = doc.to_dict() or {}
            return {
                "emailPrefs": data.get("emailPrefs", {
                    "New user registrations": True,
                    "Dispute opened": True,
                    "Payment issues": True,
                    "Scraper failures": True,
                    "Security alerts": True
                }),
                "systemPrefs": data.get("systemPrefs", {
                    "Dashboard alerts": True,
                    "Critical errors": True
                })
            }
        return {
            "emailPrefs": {
                "New user registrations": True,
                "Dispute opened": True,
                "Payment issues": True,
                "Scraper failures": True,
                "Security alerts": True
            },
            "systemPrefs": {
                "Dashboard alerts": True,
                "Critical errors": True
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/preferences")
async def update_notification_preferences(request: dict):
    try:
        from backend.database import db
        from google.cloud.firestore import SERVER_TIMESTAMP
        email_prefs = request.get("emailPrefs", {})
        system_prefs = request.get("systemPrefs", {})

        config_data = {
            "emailPrefs": email_prefs,
            "systemPrefs": system_prefs,
            "updatedAt": SERVER_TIMESTAMP
        }
        db.collection("system_config").document("notification_preferences").set(config_data, merge=True)
        return {
            "message": "Notification preferences saved successfully",
            "emailPrefs": email_prefs,
            "systemPrefs": system_prefs
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
