from firebase_admin import firestore
from datetime import datetime, timezone
from backend.database import db

class SupportService:
    @staticmethod
    def get_chats():
        chats_ref = db.collection('support_chats')
        # Order by last message time, descending
        query = chats_ref.order_by('lastMessageTime', direction=firestore.Query.DESCENDING)
        docs = query.stream()
        
        chats = []
        for doc in docs:
            chat_data = doc.to_dict()
            chat_data['id'] = doc.id
            # Convert timestamp to ISO string if needed
            if 'lastMessageTime' in chat_data and chat_data['lastMessageTime']:
                try:
                    chat_data['lastMessageTime'] = chat_data['lastMessageTime'].isoformat()
                except:
                    pass
            # Ensure userType is normalized (lowercase for consistency)
            if 'userType' in chat_data:
                chat_data['userType'] = chat_data['userType'].lower()
            
            # Enrich userName: if it's generic, fetch real name from user profile
            user_id = chat_data.get('userId')
            user_type = chat_data.get('userType', '').lower()
            current_name = chat_data.get('userName', 'User')
            
            if user_id and (current_name in ['Musician', 'Organizer', 'User']):
                try:
                    if user_type == 'musician':
                        user_doc = db.collection('musicians').document(user_id).get()
                    elif user_type == 'organizer':
                        user_doc = db.collection('organizers').document(user_id).get()
                    else:
                        user_doc = None
                    
                    if user_doc and user_doc.exists:
                        user_data = user_doc.to_dict()
                        if user_type == 'musician':
                            real_name = user_data.get('fullName', 'Musician')
                        else:
                            real_name = user_data.get('companyName') or user_data.get('fullName', 'Organizer')
                        
                        if real_name and real_name not in ['Musician', 'Organizer']:
                            chat_data['userName'] = real_name
                            # Update in Firestore to persist
                            db.collection('support_chats').document(user_id).update({
                                'userName': real_name
                            })
                except Exception as e:
                    # Silently fail, keep original name
                    pass
            
            # Enrich with profile data for display
            if user_id:
                try:
                    if user_type == 'musician':
                        user_doc = db.collection('musicians').document(user_id).get()
                    elif user_type == 'organizer':
                        user_doc = db.collection('organizers').document(user_id).get()
                    else:
                        user_doc = None
                    
                    if user_doc and user_doc.exists:
                        user_data = user_doc.to_dict()
                        # Add profile data to chat response
                        chat_data['profileImageUrl'] = user_data.get('profileImageUrl')
                        chat_data['email'] = user_data.get('email')
                        chat_data['phone'] = user_data.get('contact') or user_data.get('businessPhone')
                        chat_data['location'] = user_data.get('location')
                        chat_data['bio'] = user_data.get('bio')
                        
                        # Role-specific fields
                        if user_type == 'musician':
                            chat_data['instruments'] = user_data.get('instruments', [])
                            chat_data['genres'] = user_data.get('genres', [])
                            chat_data['experience'] = user_data.get('yearsOfExperience', 0)
                            chat_data['rating'] = user_data.get('averageRating', 0)
                        else:  # organizer
                            chat_data['orgName'] = user_data.get('orgName', user_data.get('name'))
                            chat_data['type'] = user_data.get('type')
                            chat_data['address'] = user_data.get('address')
                            chat_data['website'] = user_data.get('website')
                except Exception as e:
                    # Silently fail, proceed without profile enrichment
                    pass
            
            chats.append(chat_data)
        return chats

    @staticmethod
    def get_messages(user_id: str):
        messages_ref = db.collection('support_chats').document(user_id).collection('messages')
        # Order by timestamp ascending to get chronological order
        query = messages_ref.order_by('timestamp', direction=firestore.Query.ASCENDING)
        docs = query.stream()
        
        messages = []
        for doc in docs:
            msg = doc.to_dict()
            msg['id'] = doc.id
            if 'timestamp' in msg and msg['timestamp']:
                try:
                    msg['timestamp'] = msg['timestamp'].isoformat()
                except:
                    pass
            messages.append(msg)
            
        # Mark as read by admin if viewing
        db.collection('support_chats').document(user_id).update({
            'unreadByAdmin': False
        })
        
        return messages

    @staticmethod
    def send_message(user_id: str, text: str, sender_id: str = "admin"):
        chat_ref = db.collection('support_chats').document(user_id)
        
        # Check if chat exists, if not, create a basic placeholder 
        # (Though usually users initiate the chat, so it should exist)
        chat_doc = chat_ref.get()
        if not chat_doc.exists:
            chat_ref.set({
                'userId': user_id,
                'userType': 'unknown',
                'userName': 'User',
                'isFeatured': False,
                'unreadByAdmin': False,
                'unreadByUser': True,
                'lastMessage': text,
                'lastMessageTime': firestore.SERVER_TIMESTAMP
            })
        else:
            chat_ref.update({
                'lastMessage': text,
                'lastMessageTime': firestore.SERVER_TIMESTAMP,
                'unreadByUser': True
            })
            
        # Add the message
        msg_ref = chat_ref.collection('messages').document()
        message_data = {
            'text': text,
            'senderId': sender_id,
            'senderType': 'admin',
            'timestamp': firestore.SERVER_TIMESTAMP
        }
        msg_ref.set(message_data)
        
        return {"success": True, "message_id": msg_ref.id}
