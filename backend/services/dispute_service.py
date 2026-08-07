from firebase_admin import firestore
from backend.database import db
from backend.models.gig_models import DisputeRequest
from typing import Optional, List, Dict, Any

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
                "status": "open",
                "createdAt": firestore.SERVER_TIMESTAMP,  # type: ignore
                "updatedAt": firestore.SERVER_TIMESTAMP   # type: ignore
            }
            
            # Create dispute record
            doc_ref = db.collection("disputes").document()
            doc_ref.set(dispute_data)
            
            # Update booking status to disputed
            db.collection("bookings").document(request.bookingId).update({
                "status": "disputed"
            })
            
            from backend.services.admin_notification_service import AdminNotificationService
            AdminNotificationService.payment_alert(
                "New dispute opened",
                f"Dispute on booking {request.bookingId} — Category: {request.category}",
                {"disputeId": doc_ref.id, "bookingId": request.bookingId}
            )
            
            return doc_ref.id
        except Exception as e:
            raise e

    @staticmethod
    def get_disputes(user_id: Optional[str] = None):
        try:
            query = db.collection("disputes")
            if user_id:
                query = query.where("reporterId", "==", user_id)
                
            docs = query.get()  # type: ignore
            disputes = []
            
            for doc in docs:
                data: Dict[str, Any] = doc.to_dict() or {}
                dispute_id = doc.id
                
                # Fetch related info for admin convenience
                booking_id = data.get("bookingId")
                gig_title = "Unknown Gig"
                musician_name = "Unknown Musician"
                organizer_name = "Unknown Organizer"
                
                if booking_id:
                    booking_doc: Any = db.collection("bookings").document(booking_id).get()  # type: ignore
                    if hasattr(booking_doc, "exists") and booking_doc.exists:
                        booking_data: Dict[str, Any] = booking_doc.to_dict() or {}
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
                        from datetime import datetime
                        filed_date = datetime.fromtimestamp(created_at["seconds"]).strftime("%Y-%m-%d")

                # Map 'pending' to 'open' for the admin portal tabs
                status = data.get("status", "open")
                if status == "pending":
                    status = "open"

                attachments = data.get("attachments") or []

                disputes.append({
                    "id": dispute_id,
                    "bookingId": booking_id,
                    "reporterId": data.get("reporterId"),
                    "reporterRole": data.get("reporterRole"),
                    "priority": data.get("priority", "medium"),
                    "status": status,
                    "gigReference": gig_title,
                    "filedDate": filed_date,
                    "organizer": organizer_name,
                    "musician": musician_name,
                    "reason": data.get("category", "General"),
                    "category": data.get("category", "General"),
                    "attachments": attachments,
                    "evidenceLink": attachments[0] if len(attachments) > 0 else "No evidence",
                    "description": data.get("description", ""),
                    "resolutionAction": data.get("resolutionAction"),
                    "resolutionNotes": data.get("resolutionNotes"),
                    "resolutionAmount": data.get("resolutionAmount"),
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
    def get_dispute_by_id(dispute_id: str):
        try:
            doc: Any = db.collection("disputes").document(dispute_id).get()  # type: ignore
            if not (hasattr(doc, "exists") and doc.exists):
                return None
            data = doc.to_dict() or {}
            data["id"] = doc.id
            return data
        except Exception as e:
            raise e

    @staticmethod
    def resolve_dispute(dispute_id: str, resolution_action: Optional[str] = "refund_organizer", resolution_notes: Optional[str] = "", resolution_amount: Optional[float] = None):
        action = resolution_action or "refund_organizer"
        notes = resolution_notes or ""
        try:
            doc_ref = db.collection("disputes").document(dispute_id)
            doc: Any = doc_ref.get()  # type: ignore
            if not (hasattr(doc, "exists") and doc.exists):
                raise Exception("Dispute not found")
            
            data = doc.to_dict() or {}
            booking_id = data.get("bookingId")
            
            # Update dispute status
            doc_ref.update({
                "status": "resolved",
                "resolutionAction": action,
                "resolutionNotes": notes,
                "resolutionAmount": resolution_amount,
                "updatedAt": firestore.SERVER_TIMESTAMP  # type: ignore
            })
            
            # Update booking status depending on resolution
            if booking_id:
                booking_status = "cancelled" if action == "refund_organizer" else "completed"
                db.collection("bookings").document(booking_id).update({
                    "status": booking_status,
                    "resolutionAction": action
                })
                
            return True
        except Exception as e:
            raise e
