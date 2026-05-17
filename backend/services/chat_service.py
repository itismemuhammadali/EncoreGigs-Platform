from firebase_admin import firestore
from backend.database import db
from typing import List, Optional, Dict

class ChatService:
    @staticmethod
    def get_or_create_chat(participant_ids: List[str], participant_names: Dict[str, str], participant_images: Dict[str, str]):
        # Sort participant IDs to ensure a consistent chat ID between two users
        participant_ids.sort()
        
        # Check if chat already exists
        chats = db.collection("chats")\
                  .where("participantIds", "==", participant_ids)\
                  .limit(1)\
                  .get()
        
        if len(chats) > 0:
            return chats[0].id
            
        # Create new chat
        chat_data = {
            "participantIds": participant_ids,
            "participantNames": participant_names,
            "participantImages": participant_images,
            "lastMessage": "Chat started",
            "lastMessageTime": firestore.SERVER_TIMESTAMP,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "unreadCount": {p_id: 0 for p_id in participant_ids}
        }
        
        doc_ref = db.collection("chats").document()
        doc_ref.set(chat_data)
        return doc_ref.id
        
    @staticmethod
    def send_message(chat_id: str, sender_id: str, text: str):
        from backend.services.notification_service import NotificationService
        
        chat_ref = db.collection("chats").document(chat_id)
        chat_doc = chat_ref.get()
        if not chat_doc.exists:
            return None
            
        chat_data = chat_doc.to_dict()
        participant_ids = chat_data.get("participantIds", [])
        recipient_id = next((p_id for p_id in participant_ids if p_id != sender_id), None)
        
        # 1. Add message to subcollection
        message_data = {
            "senderId": sender_id,
            "text": text,
            "timestamp": firestore.SERVER_TIMESTAMP,
            "type": "text"
        }
        chat_ref.collection("messages").add(message_data)
        
        # 2. Update chat metadata
        chat_ref.update({
            "lastMessage": text,
            "lastMessageTime": firestore.SERVER_TIMESTAMP,
            "lastMessageSenderId": sender_id
        })
        
        # 3. Trigger Push Notification to recipient
        if recipient_id:
            sender_name = chat_data.get("participantNames", {}).get(sender_id, "Someone")
            NotificationService.send_to_user(
                user_id=recipient_id,
                title=f"Message from {sender_name}",
                body=text,
                data={"chatId": chat_id, "type": "chat"}
            )
            
        return True
