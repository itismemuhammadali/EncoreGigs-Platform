from firebase_admin import auth
from google.cloud.firestore import SERVER_TIMESTAMP
from backend.database import db
from backend.models.auth_models import ProfileUpdateRequest, OrganizationUpdateRequest, PasswordUpdateRequest, UserStatusRequest
from backend.models.musician_models import PortfolioUpdateRequest
from backend.services.security_service import SecurityService
from backend.services.email_service import EmailService
from typing import Optional, Any, Dict

class AuthService:
    @staticmethod
    def get_profile(uid: str):
        # Check admins collection
        admin_doc: Any = db.collection("admins").document(uid).get()
        if admin_doc.exists:
            doc_data = admin_doc.to_dict() or {}
            role = doc_data.get("role", "super_admin")
            return doc_data | {"id": admin_doc.id, "role": role}

        # Check organizers collection
        org_doc: Any = db.collection("organizers").document(uid).get()
        if org_doc.exists:
            return (org_doc.to_dict() or {}) | {"id": org_doc.id, "role": "organizer"}
        
        # Check musicians collection
        musician_doc: Any = db.collection("musicians").document(uid).get()
        if musician_doc.exists:
            profile_data = musician_doc.to_dict() or {}
            
            # Calculate gigs completed from bookings
            try:
                bookings_count: Any = db.collection("bookings")\
                    .where("musicianId", "==", uid)\
                    .where("status", "==", "completed")\
                    .get()
                profile_data["gigsCompleted"] = len(bookings_count)
            except Exception as e:
                print(f"Error calculating gigsCompleted: {e}")
                profile_data["gigsCompleted"] = profile_data.get("gigsCompleted", 0)
                
            return profile_data | {"id": musician_doc.id, "role": "musician"}
            
        return None

    @staticmethod
    def list_musicians():
        docs: Any = db.collection("musicians").get()
        musicians = [(doc.to_dict() or {}) | {"id": doc.id, "role": "musician"} for doc in docs]
        musicians.sort(key=lambda m: m.get("isFeatured") == True, reverse=True)
        return musicians

    @staticmethod
    def list_organizers():
        docs: Any = db.collection("organizers").get()
        return [(doc.to_dict() or {}) | {"id": doc.id, "role": "organizer"} for doc in docs]

    @staticmethod
    def update_portfolio(request: PortfolioUpdateRequest):
        user_ref = db.collection("musicians").document(request.uid)
        user_doc: Any = user_ref.get()
        
        if not user_doc.exists:
            return False
            
        data = user_doc.to_dict() or {}
        portfolio = data.get("portfolio", {})
        
        # Mapping frontend type to backend field keys
        type_map = {
            "image": "images",
            "video": "videos",
            "music": "audioTracks"
        }
        field_key = type_map.get(request.item.type)
        if not field_key:
            return False

        items = portfolio.get(field_key, [])
        item_data = request.item.model_dump()
        item_data["createdAt"] = SERVER_TIMESTAMP if request.action == "add" else None
        
        if request.action == "add":
            items.append(item_data)
        elif request.action == "update":
            found = False
            for i, it in enumerate(items):
                it_url = it.get("url") if isinstance(it, dict) else it
                if it_url == request.oldUrl:
                    items[i] = item_data
                    found = True
                    break
            if not found: return False
        elif request.action == "delete":
            items = [it for it in items if (it.get("url") if isinstance(it, dict) else it) != request.item.url]
        
        portfolio[field_key] = items
        user_ref.update({"portfolio": portfolio})
        return True

    @staticmethod
    def update_profile(request: ProfileUpdateRequest):
        user_ref = db.collection("organizers").document(request.uid)
        user_doc: Any = user_ref.get()
        role = "organizer"
        
        if not user_doc.exists:
            user_ref = db.collection("musicians").document(request.uid)
            user_doc = user_ref.get()  # type: ignore
            role = "musician"

        if not user_doc.exists:
            user_ref = db.collection("admins").document(request.uid)
            user_doc = user_ref.get()  # type: ignore
            role = "admin"
            
        if not user_doc.exists:
            return False
            
        update_data: Dict[str, Any] = {
            "email": request.email,
        }

        # Handle Name Fields
        if request.firstName is not None: update_data["firstName"] = request.firstName
        if request.lastName is not None: update_data["lastName"] = request.lastName
        
        # Determine the full name
        if request.firstName is not None or request.lastName is not None:
            # Use provided or existing values
            data = user_doc.to_dict() or {}
            f_name = request.firstName if request.firstName is not None else data.get("firstName", "")
            l_name = request.lastName if request.lastName is not None else data.get("lastName", "")
            full_name = f"{f_name} {l_name}".strip()
            update_data["name"] = full_name
            update_data["fullName"] = full_name
        elif request.name is not None:
            update_data["name"] = request.name
            update_data["fullName"] = request.name
        
        if request.contact is not None: update_data["contact"] = request.contact
        if request.location is not None: update_data["location"] = request.location
        if request.primaryCity is not None: update_data["primaryCity"] = request.primaryCity
        if request.primaryState is not None: update_data["primaryState"] = request.primaryState
        if request.primaryZip is not None: update_data["primaryZip"] = request.primaryZip
        if request.secondaryCity is not None: update_data["secondaryCity"] = request.secondaryCity
        if request.secondaryState is not None: update_data["secondaryState"] = request.secondaryState
        if request.secondaryZip is not None: update_data["secondaryZip"] = request.secondaryZip
        if request.travelRadius is not None: update_data["travelRadius"] = request.travelRadius
        if request.bio is not None: update_data["bio"] = request.bio
        if request.profileImageUrl is not None: update_data["profileImageUrl"] = request.profileImageUrl
        if request.bannerImageUrl is not None: update_data["bannerImageUrl"] = request.bannerImageUrl
        
        # Role specific fields
        if role == "musician":
            if request.instruments is not None: update_data["instruments"] = request.instruments
            if request.genres is not None: update_data["genres"] = request.genres
            if request.tags is not None: update_data["tags"] = request.tags
            if request.feeRange is not None: update_data["feeRange"] = request.feeRange
            if request.maxFeeRange is not None: update_data["maxFeeRange"] = request.maxFeeRange
            if request.yearsOfExperience is not None: update_data["yearsOfExperience"] = request.yearsOfExperience
        elif role == "organizer":
            if request.orgName is not None: update_data["orgName"] = request.orgName
            if request.type is not None: update_data["type"] = request.type
        # admins just use common fields for now

        user_ref.update(update_data)
        SecurityService.create_log("Settings updated", request.email)
        return True

    @staticmethod
    def update_organization(request: OrganizationUpdateRequest):
        user_ref = db.collection("organizers").document(request.uid)
        user_doc: Any = user_ref.get()
        
        if not user_doc.exists:
            return False
            
        update_data = {
            "orgName": request.orgName,
            "type": request.type,
            "businessEmail": request.businessEmail,
            "businessPhone": request.businessPhone,
            "address": request.address,
            "city": request.city,
            "state": request.state,
            "zipCode": request.zipCode,
            "website": request.website,
            "taxId": request.taxId,
            "description": request.description
        }
        
        if request.licenseUrl:
            update_data["licenseUrl"] = request.licenseUrl
            
        user_ref.update(update_data)
        SecurityService.create_log("Organization settings updated", request.businessEmail)
        return True

    @staticmethod
    def update_password(request: PasswordUpdateRequest):
        try:
            auth.update_user(request.uid, password=request.newPassword)
            user_doc = AuthService.get_profile(request.uid)
            email = user_doc.get("email", "Unknown") if user_doc else "Unknown"
            SecurityService.create_log("Password changed", email)
            return True
        except Exception as e:
            print(f"Error updating password: {e}")
            return False

    @staticmethod
    def update_user_status(request: UserStatusRequest):
        try:
            # Check all collections
            for collection in ["musicians", "organizers", "admins"]:
                user_ref = db.collection(collection).document(request.uid)
                user_doc: Any = user_ref.get()
                if user_doc.exists:
                    user_ref.update({"status": request.status})
                    action = f"User status set to {request.status}"
                    SecurityService.create_log(action, request.email)

                    # Trigger Twilio SendGrid automated notification email
                    user_data = user_doc.to_dict() or {}
                    user_name = user_data.get("fullName") or user_data.get("name") or "User"
                    user_email = user_data.get("email") or request.email

                    if request.status in ["approved", "active"]:
                        EmailService.send_account_approved_email(user_email, user_name)
                    elif request.status in ["rejected", "denied", "suspended"]:
                        EmailService.send_account_denied_email(user_email, user_name)

                    return True
            return False
        except Exception as e:
            print(f"Error updating user status: {e}")
            return False

    @staticmethod
    def signOut():
        pass
