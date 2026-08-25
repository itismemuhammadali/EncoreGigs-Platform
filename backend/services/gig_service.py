from typing import List, Optional, Any, Dict
from google.cloud.firestore import SERVER_TIMESTAMP, Increment, Query, FieldFilter
from backend.database import db
from backend.models.gig_models import GigRequest, ApplicationRequest

from datetime import datetime
from backend.utils.text_utils import capitalize_words, capitalize_list

def is_gig_expired(expiry_str: Optional[str]) -> bool:
    if not expiry_str:
        return False
    try:
        now = datetime.now()
        if "/" in expiry_str:
            parts = expiry_str.split("/")
            if len(parts) == 3:
                month, day, year = int(parts[0]), int(parts[1]), int(parts[2])
                exp_dt = datetime(year, month, day, 23, 59, 59)
                return now > exp_dt
        elif "-" in expiry_str:
            parts = expiry_str.split("-")
            if len(parts) == 3:
                if len(parts[0]) == 4:
                    year, month, day = int(parts[0]), int(parts[1]), int(parts[2])
                else:
                    month, day, year = int(parts[0]), int(parts[1]), int(parts[2])
                exp_dt = datetime(year, month, day, 23, 59, 59)
                return now > exp_dt
    except Exception as e:
        print(f"Error checking gig expiration for '{expiry_str}': {e}")
    return False

class GigService:
    @staticmethod
    def create_gig(request: GigRequest):
        # Fetch organizer details to ensure data integrity
        organizer_name = "Organizer"
        organizer_image = ""
        try:
            org_doc: Any = db.collection("organizers").document(request.organizerId).get()
            if org_doc.exists:
                org_data = org_doc.to_dict() or {}
                organizer_name = org_data.get("name") or org_data.get("orgName") or "Organizer"
                organizer_image = org_data.get("profileImageUrl") or ""
        except Exception as e:
            print(f"Error fetching organizer details: {e}")

        gig_data = {
            "title": capitalize_words(request.title),
            "description": request.description,
            "requirements": request.requirements,
            "genres": capitalize_list(request.genres),
            "date": request.date,
            "time": request.time,
            "expiryDate": request.expiryDate or request.date,
            "budget": request.budget,
            "location": capitalize_words(request.location),
            "organizerId": request.organizerId,
            "organizer_id": request.organizerId, # For compatibility
            "organizerName": capitalize_words(organizer_name),
            "organizerImage": organizer_image,
            "imageUrl": request.imageUrl or organizer_image, # Fallback to org image
            "duration": request.duration,
            "isUrgent": request.isUrgent,
            "status": "open",
            "applicantsCount": 0,
            "createdAt": SERVER_TIMESTAMP
        }
        doc_ref = db.collection("gigs").document()
        doc_ref.set(gig_data)

        # Trigger Notifications
        try:
            from backend.services.notification_service import NotificationService
            NotificationService.send_broadcast(
                title="New Gig Posted! 🎵",
                body=f"'{gig_data['title']}' in {gig_data['location']} is now accepting applications.",
                audience="All Users",
                notif_type="gig_created",
                data={"gigId": doc_ref.id}
            )
        except Exception as e:
            print(f"Failed to send push notifications: {e}")

        return doc_ref.id

    @staticmethod
    def get_gigs(
        status: Optional[str] = "open", 
        organizer_id: Optional[str] = None,
        search_query: Optional[str] = None
    ):
        query = db.collection("gigs")
        if status:
            query = query.where("status", "==", status)
        if organizer_id:
            query = query.where("organizerId", "==", organizer_id)
        
        docs = query.order_by("createdAt", direction=Query.DESCENDING).get()
        gigs = []
        
        for doc in docs:
            d_dict = doc.to_dict() or {}
            
            # Expiration auto-cleanup check
            exp_date = d_dict.get("expiryDate") or d_dict.get("date", "")
            if status == "open" and is_gig_expired(exp_date):
                try:
                    db.collection("gigs").document(doc.id).update({"status": "expired"})
                except Exception as ex:
                    print(f"Failed to auto-expire gig {doc.id}: {ex}")
                continue

            gig_data = {**d_dict, "id": doc.id}
            if gig_data.get("title"):
                gig_data["title"] = capitalize_words(gig_data["title"])
            if gig_data.get("location"):
                gig_data["location"] = capitalize_words(gig_data["location"])
            if gig_data.get("genres"):
                gig_data["genres"] = capitalize_list(gig_data["genres"])
            if gig_data.get("organizerName"):
                gig_data["organizerName"] = capitalize_words(gig_data["organizerName"])
            
            # Use stored counter if available, otherwise fallback to manual count
            if "applicantsCount" not in gig_data:
                apps = db.collection("applications").where("gigId", "==", doc.id).get()
                gig_data["applicantsCount"] = len(apps)
                # Sync back to doc
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
        doc: Any = db.collection("gigs").document(gig_id).get()
        if not doc.exists:
            return None
        d_dict = doc.to_dict() or {}
        gig_data = {**d_dict, "id": doc.id}
        if gig_data.get("title"):
            gig_data["title"] = capitalize_words(gig_data["title"])
        if gig_data.get("location"):
            gig_data["location"] = capitalize_words(gig_data["location"])
        if gig_data.get("genres"):
            gig_data["genres"] = capitalize_list(gig_data["genres"])
        if gig_data.get("organizerName"):
            gig_data["organizerName"] = capitalize_words(gig_data["organizerName"])
        return gig_data

    @staticmethod
    def apply_to_gig(request: ApplicationRequest):
        # Fetch musician profile to get name and image
        musician_name = "Musician"
        musician_image = ""
        m_data: Dict[str, Any] = {}
        try:
            musician_doc: Any = db.collection("musicians").document(request.musicianId).get()
            if musician_doc.exists:
                m_data = musician_doc.to_dict() or {}
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
            "appliedAt": SERVER_TIMESTAMP
        }
        
        doc_ref = db.collection("applications").document()
        doc_ref.set(application_data)
        
        # Increment applicantsCount in the gig document
        db.collection("gigs").document(request.gigId).update({
            "applicantsCount": Increment(1)
        })
        
        # Trigger Push Notification to Organizer
        from backend.services.notification_service import NotificationService
        NotificationService.send_to_user(
            user_id=request.organizerId,
            title="New Gig Application",
            body=f"{musician_name} has applied for '{request.gigTitle}'",
            notif_type="application_received",
            data={"gigId": request.gigId, "type": "application"}
        )

        # If gig is external/scraped, send polite email notification with app link to poster
        try:
            gig_doc: Any = db.collection("gigs").document(request.gigId).get()
            if gig_doc.exists:
                g_data = gig_doc.to_dict() or {}
                if g_data.get("isScraped") or g_data.get("isExternal"):
                    poster_email = g_data.get("contactEmail") or g_data.get("externalContactEmail") or g_data.get("organizerEmail")
                    if not poster_email:
                        import re
                        full_text = f"{g_data.get('title', '')} {g_data.get('description', '')}"
                        emails_found = re.findall(r'[\w\.-]+@[\w\.-]+\.\w+', full_text)
                        if emails_found:
                            poster_email = emails_found[0]

                    if poster_email:
                        from backend.services.email_service import EmailService
                        instrument = m_data.get("primaryInstrument") or m_data.get("instrument") or "Musician"
                        EmailService.send_external_applicant_email(
                            poster_email=poster_email,
                            gig_title=request.gigTitle,
                            musician_name=musician_name,
                            musician_instrument=instrument,
                            cover_message=request.coverMessage or ""
                        )
                    else:
                        print(f"GigService: External gig {request.gigId} has no public contact email to notify.")
        except Exception as e:
            print(f"Error notifying external poster via email: {e}")
        
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
            
        docs = query.order_by("appliedAt", direction=Query.DESCENDING).get()
        return [{**(doc.to_dict() or {}), "id": doc.id} for doc in docs]

    @staticmethod
    def update_application_status(application_id: str, status: str):
        app_ref = db.collection("applications").document(application_id)
        app_doc: Any = app_ref.get()
        if not app_doc.exists:
            return False
            
        app_data = app_doc.to_dict() or {}
        old_status = app_data.get("status", "pending")
        
        update_data = {"status": status}
        
        # If rejecting, save current status so we can revert
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
        status_types = {
            "shortlisted": "application_accepted",
            "accepted": "application_accepted",
            "rejected": "application_declined",
        }
        
        if status in status_titles:
            NotificationService.send_to_user(
                user_id=app_data.get("musicianId", ""),
                title=status_titles.get(status, "Application Status Updated"),
                body=f"Your application for '{app_data.get('gigTitle', 'Gig')}' is now {status}",
                notif_type=status_types.get(status, "system"),
                data={"gigId": app_data.get("gigId", ""), "type": "application_update"}
            )
        return True

    @staticmethod
    def get_recent_activity(organizer_id: str, limit: int = 10):
        activity = []
        
        try:
            gigs = db.collection("gigs").where(filter=FieldFilter("organizerId", "==", organizer_id)).order_by("createdAt", direction=Query.DESCENDING).limit(limit).get()
            for doc in gigs:
                data = doc.to_dict() or {}
                ts = data.get("createdAt")
                if ts is not None and hasattr(ts, 'isoformat') and callable(getattr(ts, 'isoformat')):
                    ts = ts.isoformat()
                activity.append({
                    "id": doc.id, "type": "gig",
                    "title": f"New gig posted: {data.get('title', 'Gig')}",
                    "subtitle": data.get("location", "Various locations"),
                    "timestamp": ts, "imageAsset": data.get("imageUrl", ""),
                    "metadata": {k: str(v) if not isinstance(v, (str, int, float, bool, list, dict, type(None))) else v for k, v in data.items()}
                })
        except Exception as e:
            print(f"Activity gigs query failed: {e}")

        try:
            apps = db.collection("applications").where(filter=FieldFilter("organizerId", "==", organizer_id)).order_by("appliedAt", direction=Query.DESCENDING).limit(limit).get()
            for doc in apps:
                data = doc.to_dict() or {}
                ts = data.get("appliedAt")
                if ts is not None and hasattr(ts, 'isoformat') and callable(getattr(ts, 'isoformat')):
                    ts = ts.isoformat()
                activity.append({
                    "id": doc.id, "type": "application",
                    "title": f"New application from {data.get('musicianName', 'Musician')}",
                    "subtitle": data.get("gigTitle", "New Gig"),
                    "timestamp": ts, "imageAsset": data.get("musicianImage", ""),
                    "metadata": {k: str(v) if not isinstance(v, (str, int, float, bool, list, dict, type(None))) else v for k, v in data.items()}
                })
        except Exception as e:
            print(f"Activity applications query failed: {e}")
            
        try:
            bookings = db.collection("bookings").where(filter=FieldFilter("organizerId", "==", organizer_id)).order_by("createdAt", direction=Query.DESCENDING).limit(limit).get()
            for doc in bookings:
                data = doc.to_dict() or {}
                ts = data.get("musicianSignedAt") or data.get("createdAt")
                if ts is not None and hasattr(ts, 'isoformat') and callable(getattr(ts, 'isoformat')):
                    ts = ts.isoformat()
                musician_signed = data.get("musicianSignedAt") is not None
                musician_name = data.get("musicianName", "Musician")
                activity.append({
                    "id": doc.id, "type": "signature",
                    "title": f"{musician_name} signed the agreement" if musician_signed else f"Booking created with {musician_name}",
                    "subtitle": data.get("gigTitle", "Gig Agreement"),
                    "timestamp": ts, "imageAsset": data.get("musicianImage", ""),
                    "metadata": {k: str(v) if not isinstance(v, (str, int, float, bool, list, dict, type(None))) else v for k, v in data.items()}
                })
        except Exception as e:
            print(f"Activity bookings query failed: {e}")
            
        try:
            chats = db.collection("chats").where(filter=FieldFilter("participantIds", "array_contains", organizer_id)).order_by("lastMessageTime", direction=Query.DESCENDING).limit(limit).get()
        
            for doc in chats:
                data = doc.to_dict() or {}
                other_participant_name = "User"
                other_participant_image = ""
                other_participant_id = ""
                p_names = data.get("participantNames", {}) if isinstance(data.get("participantNames"), dict) else {}
                p_images = data.get("participantImages", {}) if isinstance(data.get("participantImages"), dict) else {}
            
                for p_id, name in p_names.items():
                    if p_id != organizer_id:
                        other_participant_name = name
                        other_participant_id = p_id
                        other_participant_image = p_images.get(p_id, "")
                        break
                
                ts = data.get("lastMessageTime")
                if ts is not None and hasattr(ts, 'isoformat') and callable(getattr(ts, 'isoformat')):
                    ts = ts.isoformat()
                activity.append({
                    "id": doc.id, "type": "message",
                    "title": f"Message from {other_participant_name}",
                    "subtitle": data.get("lastMessage", "No messages yet"),
                    "timestamp": ts, "imageAsset": other_participant_image,
                    "metadata": {"otherUserId": other_participant_id, "otherName": other_participant_name, "otherImage": other_participant_image}
                })
        except Exception as e:
            print(f"Activity chats query failed: {e}")
            
        activity.sort(key=lambda x: str(x.get("timestamp", "")) if x.get("timestamp") else "", reverse=True)
        return activity[:limit]

    @staticmethod
    def get_musician_activity(musician_id: str, limit: int = 10):
        activity = []
        
        # 1. Recent Applications (Status updates)
        apps = db.collection("applications")\
                 .where("musicianId", "==", musician_id)\
                 .order_by("appliedAt", direction=Query.DESCENDING)\
                 .limit(limit)\
                 .get()
        
        for doc in apps:
            data = doc.to_dict() or {}
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
                "imageAsset": "",
                "metadata": data
            })
            
        # 2. Recent Bookings
        bookings = db.collection("bookings")\
                     .where("musicianId", "==", musician_id)\
                     .order_by("createdAt", direction=Query.DESCENDING)\
                     .limit(limit)\
                     .get()
        
        for doc in bookings:
            data = doc.to_dict() or {}
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
                  .order_by("lastMessageTime", direction=Query.DESCENDING)\
                  .limit(limit)\
                  .get()
        
        for doc in chats:
            data = doc.to_dict() or {}
            other_participant_name = "User"
            other_participant_image = ""
            other_participant_id = ""
            
            p_names = data.get("participantNames", {}) if isinstance(data.get("participantNames"), dict) else {}
            p_images = data.get("participantImages", {}) if isinstance(data.get("participantImages"), dict) else {}
            
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
            
        activity.sort(key=lambda x: str(x.get("timestamp", "")) if x.get("timestamp") else "", reverse=True)
        return activity[:limit]

    @staticmethod
    def get_reviews(musician_id: str, limit: int = 5):
        docs = db.collection("reviews")\
                 .where("musicianId", "==", musician_id)\
                 .order_by("createdAt", direction=Query.DESCENDING)\
                 .limit(limit)\
                 .get()
        return [{**(doc.to_dict() or {}), "id": doc.id} for doc in docs]

    @staticmethod
    def get_dashboard_stats(organizer_id: str):
        # Count gigs
        gigs = db.collection("gigs").where("organizerId", "==", organizer_id).get()
        active_gigs = [g for g in gigs if (g.to_dict() or {}).get("status") in ("open", "hired")]
        
        # Count applications
        apps = db.collection("applications").where("organizerId", "==", organizer_id).get()
        
        # Count active bookings
        bookings = db.collection("bookings").where("organizerId", "==", organizer_id).get()
        
        return {
            "totalGigs": len(gigs),
            "openGigs": len(active_gigs),
            "activeGigs": len(active_gigs), # Alias for UI
            "totalApplications": len(apps),
            "totalBookings": len(bookings), # Alias for UI
            "activeBookings": len(bookings)
        }
