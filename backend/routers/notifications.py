from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from backend.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["notifications"])


class BroadcastRequest(BaseModel):
    title: str
    message: str
    audience: str  # "All Users", "Musicians", "Organizers"
    schedule: Optional[str] = None


class RegisterTokenRequest(BaseModel):
    userId: str
    role: str  # "musician" or "organizer"
    token: str


class SendNotificationRequest(BaseModel):
    userId: str
    title: str
    body: str
    type: str = "system"


@router.post("/broadcast")
async def broadcast_notification(req: BroadcastRequest):
    result = NotificationService.send_broadcast(
        title=req.title,
        body=req.message,
        audience=req.audience,
    )
    return {"message": f"Notification sent to {result['success']} users", **result}


@router.get("/history")
async def get_broadcast_history(limit: int = 50):
    return NotificationService.get_broadcast_history(limit)


@router.get("/user/{user_id}")
async def get_user_notifications(user_id: str, limit: int = 50):
    return NotificationService.get_user_notifications(user_id, limit)


@router.get("/user/{user_id}/unread-count")
async def get_unread_count(user_id: str):
    count = NotificationService.get_unread_count(user_id)
    return {"count": count}


@router.patch("/{notification_id}/read")
async def mark_read(notification_id: str):
    success = NotificationService.mark_read(notification_id)
    if not success:
        raise HTTPException(status_code=500, detail="Failed to mark notification as read")
    return {"message": "Notification marked as read"}


@router.post("/user/{user_id}/read-all")
async def mark_all_read(user_id: str):
    success = NotificationService.mark_all_read(user_id)
    if not success:
        raise HTTPException(status_code=500, detail="Failed to mark all as read")
    return {"message": "All notifications marked as read"}


@router.post("/send")
async def send_notification(req: SendNotificationRequest):
    result = NotificationService.send_to_user(
        user_id=req.userId,
        title=req.title,
        body=req.body,
        notif_type=req.type,
    )
    if not result:
        raise HTTPException(status_code=500, detail="Failed to send notification")
    return {"message": "Notification sent", "response": result}


@router.post("/register-token")
async def register_token(req: RegisterTokenRequest):
    success = NotificationService.register_fcm_token(req.userId, req.role, req.token)
    if not success:
        raise HTTPException(status_code=500, detail="Failed to register token")
    return {"message": "FCM token registered"}
