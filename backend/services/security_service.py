from firebase_admin import firestore
from backend.database import db
from datetime import datetime

class SecurityService:
    @staticmethod
    def create_log(action: str, email: str, status: str = "success"):
        """
        Creates a new security log entry in Firestore.
        """
        try:
            log_data = {
                "action": action,
                "email": email,
                "status": status,
                "timestamp": firestore.SERVER_TIMESTAMP,
                "createdAt": datetime.now().isoformat() # For easier display if needed
            }
            db.collection("security_logs").add(log_data)
        except Exception as e:
            print(f"Error creating security log: {e}")

    @staticmethod
    def get_logs(limit: int = 50):
        """
        Retrieves recent security logs.
        """
        try:
            docs = db.collection("security_logs")\
                .order_by("timestamp", direction=firestore.Query.DESCENDING)\
                .limit(limit)\
                .get()
            
            logs = []
            for doc in docs:
                data = doc.to_dict()
                
                # Format timestamp
                timestamp = data.get("timestamp")
                date_str = ""
                if timestamp:
                    try:
                        # Convert firestore timestamp to string
                        date_str = timestamp.strftime("%Y-%m-%d %H:%M")
                    except:
                        date_str = str(timestamp)
                
                logs.append({
                    "id": doc.id,
                    "action": data.get("action", ""),
                    "email": data.get("email", ""),
                    "date": date_str,
                    "status": data.get("status", "success")
                })
            return logs
        except Exception as e:
            print(f"Error fetching security logs: {e}")
            return []
