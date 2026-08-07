from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from backend.services.support_service import SupportService

router = APIRouter(prefix="/support", tags=["support"])

class SendMessageRequest(BaseModel):
    text: str

@router.get("/chats")
async def get_chats(user_type: str = None, unread_only: bool = False):
    try:
        chats = SupportService.get_chats()
        
        # Filter by user type if provided
        if user_type:
            user_type = user_type.lower()
            chats = [c for c in chats if c.get('userType', '').lower() == user_type]
        
        # Filter unread only if requested
        if unread_only:
            chats = [c for c in chats if c.get('unreadByAdmin', False)]
        
        return chats
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/chats/{user_id}/messages")
async def get_messages(user_id: str):
    try:
        messages = SupportService.get_messages(user_id)
        return messages
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/chats/{user_id}/messages")
async def send_message(user_id: str, request: SendMessageRequest):
    try:
        result = SupportService.send_message(user_id, request.text)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
