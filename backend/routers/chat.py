from fastapi import APIRouter, HTTPException
from backend.services.chat_service import ChatService
from backend.models.chat_models import ChatRequest, SendMessageRequest

router = APIRouter(prefix="/chat", tags=["chat"])

@router.post("/get-or-create")
async def get_or_create_chat(request: ChatRequest):
    try:
        chat_id = ChatService.get_or_create_chat(
            request.participantIds,
            request.participantNames,
            request.participantImages
        )
        return {"chatId": chat_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/send-message")
async def send_message(request: SendMessageRequest):
    try:
        success = ChatService.send_message(
            request.chatId,
            request.senderId,
            request.text
        )
        if not success:
            raise HTTPException(status_code=404, detail="Chat not found")
        return {"message": "Message sent successfully"}
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))
