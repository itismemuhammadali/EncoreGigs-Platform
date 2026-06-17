from firebase_admin import firestore
from backend.database import db
from backend.models.gig_models import DisputeRequest
from typing import Optional, List

class DisputeService:
    @staticmethod
    def create_dispute(request: DisputeRequest):
        try:
            dispute_data = {
                "bookingId": request.bookingId,
                "reporterId": request.reporterId,
                "reporterRole": request.reporterRole,
                "category": request.category,
                "description": request.description,
                "attachments": request.attachments,
                "status": "open", # Changed from 'pending' to 'open'
                "createdAt": firestore.SERVER_TIMESTAMP,
                "updatedAt": firestore.SERVER_TIMESTAMP
            }
            
            # Create dispute record
            doc_ref = db.collection("disputes").document()
            doc_ref.set(dispute_data)
            
            # Update booking status to disputed
            db.collection("bookings").document(request.bookingId).update({
                "status": "disputed"
            })
            
            # Optionally trigger notification to the other party or admin
            # (Logic for notification could be added here)
            
            return doc_ref.id
        except Exception as e:
            raise e

    @staticmethod
    def get_disputes(user_id: Optional[str] = None):
        try:
            query = db.collection("disputes")
            if user_id:
                query = query.where("reporterId", "==", user_id)
                
            docs = query.get()
            disputes = []
            
            for doc in docs:
                data = doc.to_dict()
                dispute_id = doc.id
                
                # Fetch related info for admin convenience
                booking_id = data.get("bookingId")
                gig_title = "Unknown Gig"
                musician_name = "Unknown Musician"
                organizer_name = "Unknown Organizer"
                
                if booking_id:
                    booking_doc = db.collection("bookings").document(booking_id).get()
                    if booking_doc.exists:
                        booking_data = booking_doc.to_dict()
                        gig_title = booking_data.get("gigTitle", "Unknown Gig")
                        musician_name = booking_data.get("musicianName", "Unknown Musician")
                        organizer_name = booking_data.get("organizerName", "Unknown Organizer")
                
                # Format date for frontend
                created_at = data.get("createdAt")
                filed_date = "Recently"
                if created_at:
                    if hasattr(created_at, "strftime"):
                        filed_date = created_at.strftime("%Y-%m-%d")
                    elif isinstance(created_at, dict) and "seconds" in created_at:
                        # Handle dict representation if it occurs
                        from datetime import datetime
                        filed_date = datetime.fromtimestamp(created_at["seconds"]).strftime("%Y-%m-%d")

                # Map 'pending' to 'open' for the admin portal tabs
                status = data.get("status", "open")
                if status == "pending":
                    status = "open"

                disputes.append({
                    "id": dispute_id,
                    "priority": data.get("priority", "medium"),
                    "status": status,
                    "gigReference": gig_title,
                    "filedDate": filed_date,
                    "organizer": organizer_name,
                    "musician": musician_name,
                    "reason": data.get("category", "General"),
                    "evidenceLink": data.get("attachments", ["No evidence"])[0] if data.get("attachments") else "No evidence",
                    "description": data.get("description", ""),
                    "createdAt": created_at
                })

            # Sort in-memory with a safe key that handles Timestamps and None
            def sort_key(x):
                val = x.get("createdAt")
                if val is None:
                    return 0
                if hasattr(val, "timestamp"):
                    return val.timestamp()
                if isinstance(val, dict) and "seconds" in val:
                    return val["seconds"]
                try:
                    # Try converting to float if it's already a numeric type or comparable
                    return float(val)
                except:
                    return 0

            disputes.sort(key=sort_key, reverse=True)
            
            # Remove createdAt from final response to avoid serialization issues
            for d in disputes:
                d.pop("createdAt", None)
                
            return disputes
        except Exception as e:
            raise e

    @staticmethod
    def resolve_dispute(dispute_id: str):
        try:
            doc_ref = db.collection("disputes").document(dispute_id)
            doc = doc_ref.get()
            if not doc.exists:
                raise Exception("Dispute not found")
            
            data = doc.to_dict()
            booking_id = data.get("bookingId")
            
            # Update dispute status
            doc_ref.update({
                "status": "resolved",
                "updatedAt": firestore.SERVER_TIMESTAMP
            })
            
            # Update booking status back to a normal state (e.g., 'completed' or 'confirmed')
            if booking_id:
                db.collection("bookings").document(booking_id).update({
                    "status": "completed" # Assuming resolution means completion for now
                })
                
            return True
        except Exception as e:
            raise e
