from firebase_admin import firestore
from backend.database import db
from backend.models.gig_models import GigRequest, ApplicationRequest
from typing import List, Optional

class GigService:
    @staticmethod
    def create_gig(request: GigRequest):
        # Fetch organizer details to ensure data integrity
        organizer_name = "Organizer"
        organizer_image = ""
        try:
            org_doc = db.collection("organizers").document(request.organizerId).get()
            if org_doc.exists:
                org_data = org_doc.to_dict()
                organizer_name = org_data.get("name") or org_data.get("orgName") or "Organizer"
                organizer_image = org_data.get("profileImageUrl") or ""
        except Exception as e:
            print(f"Error fetching organizer details: {e}")

        gig_data = {
            "title": request.title,
            "description": request.description,
            "requirements": request.requirements,
            "genres": request.genres,
            "date": request.date,
            "time": request.time,
            "budget": request.budget,
            "location": request.location,
            "organizerId": request.organizerId,
            "organizer_id": request.organizerId, # For compatibility
            "organizerName": organizer_name,
            "organizerImage": organizer_image,
            "imageUrl": request.imageUrl or organizer_image, # Fallback to org image
            "duration": request.duration,
            "status": "open",
            "applicantsCount": 0,
            "createdAt": firestore.SERVER_TIMESTAMP
        }
        doc_ref = db.collection("gigs").document()
        doc_ref.set(gig_data)
        return doc_ref.id

    @staticmethod
    def get_gigs(status: Optional[str] = None, organizer_id: Optional[str] = None, search_query: Optional[str] = None):
        query = db.collection("gigs")
        if status:
            query = query.where("status", "==", status)
        if organizer_id:
            query = query.where("organizerId", "==", organizer_id)
        
        docs = query.order_by("createdAt", direction=firestore.Query.DESCENDING).get()
        gigs = []
        
        for doc in docs:
            gig_data = doc.to_dict() | {"id": doc.id}
            
            # Use stored counter if available, otherwise fallback to manual count
            if "applicantsCount" not in gig_data:
                apps = db.collection("applications").where("gigId", "==", doc.id).get()
                gig_data["applicantsCount"] = len(apps)
                # Optionally sync it back to the doc
                db.collection("gigs").document(doc.id).update({"applicantsCount": len(apps)})
            
            gigs.append(gig_data)
        
        if search_query:
            search_query = search_query.lower()
            gigs = [
                g for g in gigs 
                if search_query in g.get("title", "").lower() or 
                   search_query in g.get("description", "").lower() or
                   any(search_query in genre.lower() for genre in g.get("genres", [])) or
                   search_query in g.get("location", "").lower()
            ]
            
        return gigs

    @staticmethod
    def get_gig_by_id(gig_id: str):
        doc = db.collection("gigs").document(gig_id).get()
        if not doc.exists:
            return None
        return doc.to_dict() | {"id": doc.id}

    @staticmethod
    def apply_to_gig(request: ApplicationRequest):
        # Fetch musician profile to get name and image
        musician_name = "Musician"
        musician_image = ""
        try:
            musician_doc = db.collection("musicians").document(request.musicianId).get()
            if musician_doc.exists:
                m_data = musician_doc.to_dict()
                musician_name = m_data.get("fullName") or m_data.get("name") or m_data.get("displayName") or "Musician"
                musician_image = m_data.get("profileImageUrl") or m_data.get("imageUrl") or ""
        except Exception as e:
            print(f"Could not fetch musician profile: {e}")

        application_data = {
            "gigId": request.gigId,
            "gigTitle": request.gigTitle,
            "musicianId": request.musicianId,
            "musicianName": musician_name,
            "musicianImage": musician_image,
            "organizerId": request.organizerId,
            "organizer_id": request.organizerId, # For compatibility
            "organizerName": request.organizerName,
            "gigDate": request.gigDate,
            "gigTime": request.gigTime,
            "duration": request.duration,
            "proposedRate": request.proposedRate,
            "coverMessage": request.coverMessage,
            "attachments": request.attachments,
            "status": request.status,
            "appliedAt": firestore.SERVER_TIMESTAMP
        }
        
        doc_ref = db.collection("applications").document()
        doc_ref.set(application_data)
        
        # Increment applicantsCount in the gig document
        db.collection("gigs").document(request.gigId).update({
            "applicantsCount": firestore.Increment(1)
        })
        
        # 4. Trigger Push Notification to Organizer
        from backend.services.notification_service import NotificationService
        NotificationService.send_to_user(
            user_id=request.organizerId,
            title="New Gig Application",
            body=f"{musician_name} has applied for '{request.gigTitle}'",
            data={"gigId": request.gigId, "type": "application"}
        )
        
        return doc_ref.id

    @staticmethod
    def get_applications(gig_id: Optional[str] = None, musician_id: Optional[str] = None, organizer_id: Optional[str] = None, status: Optional[str] = None):
        query = db.collection("applications")
        if gig_id:
            query = query.where("gigId", "==", gig_id)
        if musician_id:
            query = query.where("musicianId", "==", musician_id)
        if organizer_id:
            query = query.where("organizerId", "==", organizer_id)
        if status:
            query = query.where("status", "==", status)
            
        docs = query.order_by("appliedAt", direction=firestore.Query.DESCENDING).get()
        return [doc.to_dict() | {"id": doc.id} for doc in docs]

    @staticmethod
    def update_application_status(application_id: str, status: str):
        app_ref = db.collection("applications").document(application_id)
        app_doc = app_ref.get()
        if not app_doc.exists:
            return False
            
        app_data = app_doc.to_dict()
        old_status = app_data.get("status", "pending")
        
        update_data = {"status": status}
        
        # If we are rejecting, save the current status so we can revert to it
        if status == "rejected" and old_status != "rejected":
            update_data["previousStatus"] = old_status
            
        app_ref.update(update_data)
        
        # Notify Musician
        from backend.services.notification_service import NotificationService
        status_titles = {
            "shortlisted": "You've been shortlisted!",
            "accepted": "Application accepted!",
            "rejected": "Application update",
        }
        
        if status in status_titles:
            NotificationService.send_to_user(
                user_id=app_data["musicianId"],
                title=status_titles.get(status, "Application Status Updated"),
                body=f"Your application for '{app_data['gigTitle']}' is now {status}",
                data={"gigId": app_data["gigId"], "type": "application_update"}
            )
        return True

    @staticmethod
    def get_recent_activity(organizer_id: str, limit: int = 10):
        activity = []
        
        # 1. Recent Gigs Posted
        gigs = db.collection("gigs")\
                 .where("organizerId", "==", organizer_id)\
                 .order_by("createdAt", direction=firestore.Query.DESCENDING)\
                 .limit(limit)\
                 .get()
        
        for doc in gigs:
            data = doc.to_dict()
            activity.append({
                "id": doc.id,
                "type": "gig",
                "title": f"New gig posted: {data.get('title', 'Gig')}",
                "subtitle": data.get("location", "Various locations"),
                "timestamp": data.get("createdAt"),
                "imageAsset": data.get("imageUrl", ""),
                "metadata": data
            })

        # 2. Recent Applications
        apps = db.collection("applications")\
                 .where("organizerId", "==", organizer_id)\
                 .order_by("appliedAt", direction=firestore.Query.DESCENDING)\
                 .limit(limit)\
                 .get()
        
        for doc in apps:
            data = doc.to_dict()
            activity.append({
                "id": doc.id,
                "type": "application",
                "title": f"New application from {data.get('musicianName', 'Musician')}",
                "subtitle": data.get("gigTitle", "New Gig"),
                "timestamp": data.get("appliedAt"),
                "imageAsset": data.get("musicianImage", ""),
                "metadata": data
            })
            
        # 2. Recent Bookings/Signatures
        bookings = db.collection("bookings")\
                     .where("organizerId", "==", organizer_id)\
                     .order_by("createdAt", direction=firestore.Query.DESCENDING)\
                     .limit(limit)\
                     .get()
        
        for doc in bookings:
            data = doc.to_dict()
            musician_signed = data.get("musicianSignedAt") is not None
            musician_name = data.get("musicianName", "Musician")
            
            activity.append({
                "id": doc.id,
                "type": "signature",
                "title": f"{musician_name} signed the agreement" if musician_signed else f"Booking created with {musician_name}",
                "subtitle": data.get("gigTitle", "Gig Agreement"),
                "timestamp": data.get("musicianSignedAt") or data.get("createdAt"),
                "imageAsset": data.get("musicianImage", ""),
                "metadata": data
            })
            
        # 3. Recent Chats (simplified - just getting chat entries where user is participant)
        chats = db.collection("chats")\
                  .where("participantIds", "array_contains", organizer_id)\
                  .order_by("lastMessageTime", direction=firestore.Query.DESCENDING)\
                  .limit(limit)\
                  .get()
        
        for doc in chats:
            data = doc.to_dict()
            # Find the other participant's name/image
            other_participant_name = "User"
            other_participant_image = ""
            other_participant_id = ""
            
            p_names = data.get("participantNames", {})
            p_images = data.get("participantImages", {})
            
            for p_id, name in p_names.items():
                if p_id != organizer_id:
                    other_participant_name = name
                    other_participant_id = p_id
                    other_participant_image = p_images.get(p_id, "")
                    break
            
            activity.append({
                "id": doc.id,
                "type": "message",
                "title": f"Message from {other_participant_name}",
                "subtitle": data.get("lastMessage", "No messages yet"),
                "timestamp": data.get("lastMessageTime"),
                "imageAsset": other_participant_image,
                "metadata": {
                    "otherUserId": other_participant_id,
                    "otherName": other_participant_name,
                    "otherImage": other_participant_image
                }
            })
            
        # Sort combined activity by timestamp descending
        activity.sort(key=lambda x: x["timestamp"] if x["timestamp"] else 0, reverse=True)
        return activity[:limit]

    @staticmethod
    def get_musician_activity(musician_id: str, limit: int = 10):
        activity = []
        
        # 1. Recent Applications (Status updates)
        apps = db.collection("applications")\
                 .where("musicianId", "==", musician_id)\
                 .order_by("appliedAt", direction=firestore.Query.DESCENDING)\
                 .limit(limit)\
                 .get()
        
        for doc in apps:
            data = doc.to_dict()
            status = data.get("status", "pending")
            status_text = {
                "pending": "Application submitted",
                "shortlisted": "You've been shortlisted!",
                "accepted": "Application accepted!",
                "rejected": "Application declined",
                "hired": "You've been hired!"
            }.get(status, f"Status update: {status}")

            activity.append({
                "id": doc.id,
                "type": "application",
                "title": status_text,
                "subtitle": data.get("gigTitle", "Gig"),
                "timestamp": data.get("appliedAt"),
                "imageAsset": "", # Could be organizer logo
                "metadata": data
            })
            
        # 2. Recent Bookings (Contract signatures required)
        bookings = db.collection("bookings")\
                     .where("musicianId", "==", musician_id)\
                     .order_by("createdAt", direction=firestore.Query.DESCENDING)\
                     .limit(limit)\
                     .get()
        
        for doc in bookings:
            data = doc.to_dict()
            organizer_name = data.get("organizerName", "Organizer")
            
            activity.append({
                "id": doc.id,
                "type": "booking",
                "title": f"New booking from {organizer_name}",
                "subtitle": "Agreement ready for signature",
                "timestamp": data.get("createdAt"),
                "imageAsset": "",
                "metadata": data
            })
            
        # 3. Recent Chats
        chats = db.collection("chats")\
                  .where("participantIds", "array_contains", musician_id)\
                  .order_by("lastMessageTime", direction=firestore.Query.DESCENDING)\
                  .limit(limit)\
                  .get()
        
        for doc in chats:
            data = doc.to_dict()
            other_participant_name = "User"
            other_participant_image = ""
            other_participant_id = ""
            
            p_names = data.get("participantNames", {})
            p_images = data.get("participantImages", {})
            
            for p_id, name in p_names.items():
                if p_id != musician_id:
                    other_participant_name = name
                    other_participant_id = p_id
                    other_participant_image = p_images.get(p_id, "")
                    break
            
            activity.append({
                "id": doc.id,
                "type": "message",
                "title": f"Message from {other_participant_name}",
                "subtitle": data.get("lastMessage", "No messages yet"),
                "timestamp": data.get("lastMessageTime"),
                "imageAsset": other_participant_image,
                "metadata": {
                    "otherUserId": other_participant_id,
                    "otherName": other_participant_name,
                    "otherImage": other_participant_image
                }
            })
            
        activity.sort(key=lambda x: x["timestamp"] if x["timestamp"] else 0, reverse=True)
        return activity[:limit]

    @staticmethod
    def get_reviews(musician_id: str, limit: int = 5):
        docs = db.collection("reviews")\
                 .where("musicianId", "==", musician_id)\
                 .order_by("createdAt", direction=firestore.Query.DESCENDING)\
                 .limit(limit)\
                 .get()
        return [doc.to_dict() | {"id": doc.id} for doc in docs]

    @staticmethod
    def get_dashboard_stats(organizer_id: str):
        # Count gigs
        gigs = db.collection("gigs").where("organizerId", "==", organizer_id).get()
        open_gigs = [g for g in gigs if g.get("status") == "open"]
        
        # Count applications
        apps = db.collection("applications").where("organizerId", "==", organizer_id).get()
        
        # Count active bookings
        bookings = db.collection("bookings").where("organizerId", "==", organizer_id).get()
        
        return {
            "totalGigs": len(gigs),
            "openGigs": len(open_gigs),
            "activeGigs": len(open_gigs), # Alias for UI
            "totalApplications": len(apps),
            "totalBookings": len(bookings), # Alias for UI
            "activeBookings": len(bookings)
        }
