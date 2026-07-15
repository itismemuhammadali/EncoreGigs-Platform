from fastapi import APIRouter, HTTPException, Query, File, UploadFile
from typing import Optional, List, Dict, Any
from firebase_admin import auth, firestore
import urllib3
import json as _json
from backend.services.auth_service import AuthService
from backend.services.storage_service import StorageService
from backend.services.security_service import SecurityService
from backend.models.auth_models import SignUpRequest, SignInRequest, ProfileUpdateRequest, OrganizationUpdateRequest, AdminSignUpRequest, ForgotPasswordRequest, PasswordUpdateRequest, UserStatusRequest
from backend.models.musician_models import MusicianSignUpRequest, PortfolioUpdateRequest

router = APIRouter(prefix="/auth", tags=["auth"])

FIREBASE_WEB_API_KEY = "AIzaSyChynuewEnIYF376H9BDQr87BMtBmZmgjQ"
FIREBASE_IDENTITY_TOOLKIT_URL = "https://identitytoolkit.googleapis.com/v1"

def _firebase_auth_request(endpoint, payload):
    """Call Firebase Identity Toolkit API directly, bypassing any emulator env var interception."""
    url = f"{FIREBASE_IDENTITY_TOOLKIT_URL}/{endpoint}?key={FIREBASE_WEB_API_KEY}"
    http = urllib3.PoolManager()
    response = http.request(
        'POST',
        url,
        body=_json.dumps(payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'},
    )
    return _json.loads(response.data.decode('utf-8'))

@router.post("/upload")
async def upload_file(uid: str, file_type: str, file: UploadFile = File(...)):
    try:
        content = await file.read()
        path = StorageService.get_upload_path(uid, file_type, file.filename)
        public_url = StorageService.upload_file(content, path, file.content_type)
        
        # Automatically update database if it's a profile photo
        if file_type == "profile_photo":
            try:
                from backend.database import db
                print(f"DEBUG: Updating Firestore for UID: {uid}")
                # Check which collection the user is in
                updated = False
                for collection in ["admins", "musicians", "organizers"]:
                    user_ref = db.collection(collection).document(uid)
                    if user_ref.get().exists:
                        user_ref.update({"profileImageUrl": public_url})
                        print(f"DEBUG: Successfully updated {collection} document")
                        updated = True
                        break
                if not updated:
                    print(f"DEBUG: No document found for UID {uid} in any collection")
            except Exception as db_err:
                print(f"DATABASE UPDATE ERROR: {str(db_err)}")
                # Don't fail the whole request if just the DB update fails, 
                # but we'll know about it from the logs.

        return {"url": public_url, "path": path}
    except Exception as e:
        import traceback
        print(f"UPLOAD ERROR: {str(e)}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/forgot-password")
async def forgot_password(request: ForgotPasswordRequest):
    payload = {
        "requestType": "PASSWORD_RESET",
        "email": request.email
    }
    
    try:
        data = _firebase_auth_request("accounts:sendOobCode", payload)
        
        if "error" in data:
            raise HTTPException(status_code=400, detail=data["error"]["message"])
            
        SecurityService.create_log("Password reset requested", request.email)
        return {"message": "Reset email sent successfully"}
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/portfolio/update")
async def update_portfolio(request: PortfolioUpdateRequest):
    try:
        success = AuthService.update_portfolio(request)
        if not success:
            raise HTTPException(status_code=404, detail="Musician not found or invalid type")
        return {"message": "Portfolio updated successfully"}
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/storage/upload-path")
async def get_upload_path(
    uid: str, 
    file_type: str, 
    filename: Optional[str] = Query(None)
):
    try:
        from backend.services.storage_service import StorageService
        path = StorageService.get_upload_path(uid, file_type, filename)
        return {"path": path}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/musicians")
async def list_musicians():
    try:
        return AuthService.list_musicians()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/organizers")
async def list_organizers():
    try:
        return AuthService.list_organizers()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/profile/{uid}")
async def get_profile(uid: str):
    try:
        profile = AuthService.get_profile(uid)
        if not profile:
            raise HTTPException(status_code=404, detail="User not found")
        return profile
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/profile/update")
async def update_profile(request: ProfileUpdateRequest):
    try:
        success = AuthService.update_profile(request)
        if not success:
            raise HTTPException(status_code=404, detail="User not found")
        return {"message": "Profile updated successfully"}
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/organization/update")
async def update_organization(request: OrganizationUpdateRequest):
    try:
        success = AuthService.update_organization(request)
        if not success:
            raise HTTPException(status_code=404, detail="Organizer not found")
        return {"message": "Organization updated successfully"}
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/signup/admin")
async def signup_admin(request: AdminSignUpRequest):
    try:
        from datetime import datetime
        full_name = f"{request.firstName} {request.lastName}"
        user = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=full_name
        )
        
        from backend.database import db
        user_data = {
            "uid": user.uid,
            "firstName": request.firstName,
            "lastName": request.lastName,
            "name": full_name,
            "email": request.email,
            "role": "admin",
            "joinedAt": datetime.now().strftime("%Y-%m-%d"),
            "createdAt": firestore.SERVER_TIMESTAMP
        }
        db.collection("admins").document(user.uid).set(user_data)
        
        return {"message": "Admin created successfully", "uid": user.uid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/signup/musician")
async def signup_musician(request: MusicianSignUpRequest):
    try:
        from datetime import datetime
        # Create user in Firebase Auth
        user = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=request.fullName
        )
        
        # Store in Firestore via Service
        from backend.database import db
        user_data = {
            "uid": user.uid,
            "fullName": request.fullName,
            "email": request.email,
            "bio": request.bio,
            "genres": request.genres,
            "instruments": request.instruments,
            "feeRange": request.feeRange,
            "yearsOfExperience": request.yearsOfExperience,
            "location": request.location,
            "website": request.website,
            "portfolio": request.portfolio,
            "profileImageUrl": request.profileImageUrl,
            "status": "pending",
            "role": "musician",
            "joinedAt": datetime.now().strftime("%Y-%m-%d"),
            "createdAt": firestore.SERVER_TIMESTAMP
        }
        db.collection("musicians").document(user.uid).set(user_data)
        
        return {"message": "Musician created successfully", "uid": user.uid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/signup")
async def signup(request: SignUpRequest):
    try:
        from datetime import datetime
        user = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=request.name
        )
        
        from backend.database import db
        user_data = {
            "uid": user.uid,
            "name": request.name,
            "orgName": request.orgName,
            "email": request.email,
            "businessEmail": request.email,
            "type": request.type,
            "contact": request.contact,
            "businessPhone": request.contact,
            "location": request.location,
            "bio": request.bio,
            "status": "pending",
            "role": "organizer",
            "joinedAt": datetime.now().strftime("%Y-%m-%d"),
            "createdAt": firestore.SERVER_TIMESTAMP
        }
        db.collection("organizers").document(user.uid).set(user_data)
        
        return {"message": "User created successfully", "uid": user.uid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/password/update")
async def update_password(request: PasswordUpdateRequest):
    try:
        success = AuthService.update_password(request)
        if not success:
            raise HTTPException(status_code=400, detail="Failed to update password")
        return {"message": "Password updated successfully"}
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/user/status")
async def update_user_status(request: UserStatusRequest):
    try:
        success = AuthService.update_user_status(request)
        if not success:
            raise HTTPException(status_code=400, detail="Failed to update user status")
        return {"message": f"User status updated to {request.status} successfully"}
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/signin")
async def signin(request: SignInRequest):
    payload = {
        "email": request.email,
        "password": request.password,
        "returnSecureToken": True
    }
    
    try:
        data = _firebase_auth_request("accounts:signInWithPassword", payload)
        
        if "error" in data:
            SecurityService.create_log("Failed login attempt", request.email, status="failed")
            raise HTTPException(status_code=401, detail=data["error"]["message"])
        
        uid = data["localId"]
        profile = AuthService.get_profile(uid)
        role = profile["role"] if profile else "unknown"
        display_name = profile.get("name") or profile.get("fullName") if profile else "User"
        profile_image = profile.get("profileImageUrl") if profile else None
        
        # Log based on role
        action = "Admin login" if role == "admin" else f"{role.capitalize()} login"
        SecurityService.create_log(action, request.email)
        
        return {
            "idToken": data["idToken"],
            "email": data["email"],
            "localId": uid,
            "role": role,
            "displayName": display_name,
            "profileImageUrl": profile_image
        }
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        SecurityService.create_log("Failed login attempt", request.email, status="failed")
        raise HTTPException(status_code=500, detail=str(e))
