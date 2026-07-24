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
