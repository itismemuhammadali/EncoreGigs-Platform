from pydantic import BaseModel
from typing import List, Dict

class ChatRequest(BaseModel):
    participantIds: List[str]
    participantNames: Dict[str, str]
    participantImages: Dict[str, str]

class SendMessageRequest(BaseModel):
    chatId: str
    senderId: str
    text: str
