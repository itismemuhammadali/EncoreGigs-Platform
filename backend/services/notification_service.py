from firebase_admin import messaging
from typing import Optional, Dict

class NotificationService:
    @staticmethod
    def send_to_user(user_id: str, title: str, body: str, data: Optional[Dict[str, str]] = None):
        """
        Sends a push notification to a specific user via their FCM token.
        Note: This assumes user tokens are stored in the 'users' or role-specific collection.
        """
        from backend.database import db
        
        # Try to find token in organizers or musicians
        user_doc = db.collection("organizers").document(user_id).get()
        if not user_doc.exists:
            user_doc = db.collection("musicians").document(user_id).get()
            
        if not user_doc.exists:
            print(f"No user found for notification: {user_id}")
            return
            
        token = user_doc.to_dict().get("fcmToken")
        if not token:
            print(f"No FCM token found for user: {user_id}")
            return

        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=token,
        )

        try:
            response = messaging.send(message)
            print('Successfully sent message:', response)
            return response
        except Exception as e:
            print('Error sending message:', e)
            return None
