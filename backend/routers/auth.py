import os
import secrets
import smtplib
import urllib3
import json as _json
import traceback
from datetime import datetime, timedelta, timezone
from typing import Optional, List, Dict, Any

from fastapi import APIRouter, HTTPException, Query, File, UploadFile, Response
import io
import re
import zipfile
import urllib.request
from pydantic import BaseModel
from firebase_admin import auth, firestore
from google.cloud.firestore import SERVER_TIMESTAMP

from backend.database import db
from backend.services.auth_service import AuthService
from backend.services.storage_service import StorageService
from backend.services.security_service import SecurityService
from backend.services.admin_notification_service import AdminNotificationService
from backend.services.email_service import EmailService
from backend.models.auth_models import (
    SignUpRequest,
    SignInRequest,
    ProfileUpdateRequest,
    OrganizationUpdateRequest,
    AdminSignUpRequest,
    ForgotPasswordRequest,
    PasswordUpdateRequest,
    UserStatusRequest,
    SendEmailOTPRequest,
    VerifyEmailOTPRequest,
    Enable2FARequest,
    Set2FAMethodRequest,
    SavePhoneNumberRequest,
    SendEmailLink2FARequest,
    CreateAdminMemberRequest,
    SendApprovalEmailRequest,
)
from backend.models.musician_models import MusicianSignUpRequest, PortfolioUpdateRequest


router = APIRouter(prefix="/auth", tags=["auth"])

FIREBASE_WEB_API_KEY = os.getenv("FIREBASE_WEB_API_KEY", "AIzaSyChynuewEnIYF376H9BDQr87BMtBmZmgjQ")
FIREBASE_IDENTITY_TOOLKIT_URL = "https://identitytoolkit.googleapis.com/v1"


class SendVerificationRequest(BaseModel):
    email: str
    id_token: str


class CheckVerificationRequest(BaseModel):
    uid: str


class CreateUserRequest(BaseModel):
    email: str
    password: str


class DeleteAccountRequest(BaseModel):
    uid: str


class ExportDataRequest(BaseModel):
    uid: str


def _firebase_auth_request(endpoint: str, payload: Dict[str, Any]) -> Dict[str, Any]:
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
        filename = file.filename or "file"
        content_type = file.content_type or "image/jpeg"
        path = StorageService.get_upload_path(uid, file_type, filename)
        public_url = StorageService.upload_file(content, path, content_type)
        
        # Automatically update database if it's a profile photo
        if file_type == "profile_photo":
            try:
                print(f"DEBUG: Updating Firestore for UID: {uid}")
                updated = False
                for collection in ["admins", "musicians", "organizers"]:
                    user_ref = db.collection(collection).document(uid)
                    doc: Any = user_ref.get()
                    if doc.exists:
                        user_ref.update({"profileImageUrl": public_url})
                        print(f"DEBUG: Successfully updated {collection} document")
                        updated = True
                        break
                if not updated:
                    print(f"DEBUG: No document found for UID {uid} in any collection")
            except Exception as db_err:
                print(f"DATABASE UPDATE ERROR: {str(db_err)}")

        return {"url": public_url, "path": path}
    except Exception as e:
        print(f"UPLOAD ERROR: {str(e)}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/forgot-password")
async def forgot_password(request: ForgotPasswordRequest):
    clean_email = request.email.strip()
    if request.role:
        collection_name = (
            "musicians"
            if request.role == "musician"
            else ("organizers" if request.role == "organizer" else f"{request.role}s")
        )
        docs = db.collection(collection_name).where("email", "==", clean_email.lower()).limit(1).get()
        if not docs:
            docs = db.collection(collection_name).where("email", "==", clean_email).limit(1).get()
        if not docs:
            if request.role == "musician":
                raise HTTPException(status_code=400, detail="Entertainer does not exist")
            elif request.role == "organizer":
                raise HTTPException(status_code=400, detail="Organizer does not exist")
            else:
                raise HTTPException(status_code=400, detail="No account found with this email address.")

    payload = {
        "requestType": "PASSWORD_RESET",
        "email": clean_email
    }
    
    try:
        data = _firebase_auth_request("accounts:sendOobCode", payload)
        
        if "error" in data:
            err_msg = data["error"].get("message", "Failed to send password reset email") if isinstance(data["error"], dict) else str(data["error"])
            if err_msg == "EMAIL_NOT_FOUND":
                if request.role == "musician":
                    raise HTTPException(status_code=400, detail="Entertainer does not exist")
                elif request.role == "organizer":
                    raise HTTPException(status_code=400, detail="Organizer does not exist")
                else:
                    raise HTTPException(status_code=400, detail="No account found with this email address.")
            if "TOO_MANY_ATTEMPTS" in err_msg or "RESET_PASSWORD_EXCEED_LIMIT" in err_msg:
                raise HTTPException(
                    status_code=429,
                    detail="Too many attempts. Please wait a few minutes before trying again."
                )
            raise HTTPException(status_code=400, detail=err_msg.replace("_", " "))
            
        SecurityService.create_log("Password reset requested", clean_email)
        return {"message": "Reset email sent successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def _send_otp_email(to_email: str, otp_code: str, uid: Optional[str] = None) -> bool:
    try:
        resend_api_key = os.getenv("RESEND_API_KEY")
        
        if not resend_api_key or "your_resend_api_key" in resend_api_key:
            print(f"\n{'='*60}")
            print(f"🔑 [DEV MODE] VERIFICATION EMAIL LINK / OTP FOR {to_email}:")
            print(f"{'='*60}")
            print(f"{otp_code}")
            print(f"{'='*60}\n")
            return True
        
        import resend as _resend  # type: ignore
        resend: Any = _resend
        resend.api_key = resend_api_key
        
        html_body = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; }}
        .container {{ max-width: 600px; margin: 0 auto; }}
    </style>
</head>
<body style="background-color: #f9f9f9; padding: 20px; margin: 0;">
    <div class="container" style="background-color: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
        <div style="text-align: center; margin-bottom: 40px;">
            <h1 style="color: #0A0A0F; font-size: 28px; margin: 0;">🎵 OnlyGigz</h1>
            <p style="color: #999; font-size: 14px; margin: 5px 0 0 0;">Where Music Meets Opportunity</p>
        </div>
        
        <h2 style="color: #333; font-size: 24px; margin: 20px 0;">Email Verification</h2>
        <p style="color: #666; font-size: 16px; line-height: 1.6; margin: 20px 0;">
            Hello,
        </p>
        <p style="color: #666; font-size: 16px; line-height: 1.6; margin: 20px 0;">
            Your one-time verification code is:
        </p>
        
        <div style="background-color: #0A0A0F; padding: 40px; text-align: center; border-radius: 8px; margin: 40px 0;">
            <h1 style="letter-spacing: 10px; color: #A1F301; font-family: 'Courier New', monospace; font-size: 56px; margin: 0; font-weight: bold;">{otp_code}</h1>
        </div>
        
        <p style="color: #666; font-size: 16px; line-height: 1.6; margin: 20px 0;">
            This code will expire in <strong>10 minutes</strong>.
        </p>
        
        <p style="color: #666; font-size: 16px; line-height: 1.6; margin: 20px 0;">
            If you did not request this code, please ignore this email and your account will remain secure.
        </p>
        
        <hr style="border: none; border-top: 1px solid #ddd; margin: 40px 0;">
        
        <p style="color: #999; font-size: 12px; margin: 20px 0; text-align: center;">
            © 2025 OnlyGigz. All rights reserved.<br>
            <a href="https://onlygigz.com" style="color: #A1F301; text-decoration: none;">Visit OnlyGigz</a>
        </p>
    </div>
</body>
</html>
        """
        
        response = resend.Emails.send({
            "from": "onboarding@resend.dev",
            "to": to_email,
            "subject": "OnlyGigz - Your Verification Code",
            "html": html_body
        })
        
        print(f"\n{'='*60}")
        print(f"📧 OTP EMAIL SENT: To {to_email}")
        print(f"{'='*60}\n")
        return True
        
    except ValueError as e:
        print(f"\n⚠️ RESEND CONFIGURATION ERROR: {e}\n")
        raise
    except Exception as e:
        print(f"\n❌ RESEND EMAIL FAILED: {e}\n")
        raise


@router.post("/send-email-otp")
async def send_email_otp(request: SendEmailOTPRequest):
    try:
        print(f"\n{'='*70}")
        print(f"🔷 SEND EMAIL OTP ENDPOINT CALLED: {request.email}")
        print(f"{'='*70}")
        
        COOLDOWN_SECONDS = 30
        otp_doc: Any = db.collection("otps").document(request.email).get()
        
        if otp_doc.exists:
            existing_data = otp_doc.to_dict()
            created_at = existing_data.get("createdAt")
            
            if created_at:
                if hasattr(created_at, 'timestamp'):
                    created_time = datetime.fromtimestamp(created_at.timestamp(), tz=timezone.utc)
                elif isinstance(created_at, datetime):
                    created_time = created_at if created_at.tzinfo else created_at.replace(tzinfo=timezone.utc)
                else:
                    created_time = None

                if created_time:
                    elapsed = (datetime.now(timezone.utc) - created_time).total_seconds()
                    if elapsed < COOLDOWN_SECONDS:
                        remaining = int(COOLDOWN_SECONDS - elapsed)
                        raise HTTPException(
                            status_code=429,
                            detail=f"Please wait {remaining} seconds before requesting another code."
                        )
        
        otp_code = "".join([str(secrets.randbelow(10)) for _ in range(6)])
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=10)
        
        db.collection("otps").document(request.email).set({
            "email": request.email,
            "otp": otp_code,
            "uid": request.uid,
            "createdAt": SERVER_TIMESTAMP,
            "expiresAt": expires_at
        })
        
        _send_otp_email(request.email, otp_code, request.uid)
        return {"message": "OTP code sent successfully", "expiresIn": 600}
        
    except HTTPException:
        raise
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/verify-email-otp")
async def verify_email_otp(request: VerifyEmailOTPRequest):
    try:
        doc_ref = db.collection("otps").document(request.email)
        doc: Any = doc_ref.get()
        
        if not doc.exists:
            raise HTTPException(status_code=400, detail="No active OTP found for this email. Please request a new one.")
            
        data = doc.to_dict()
        
        expires_at = data.get("expiresAt")
        if expires_at and datetime.now(timezone.utc) > expires_at:
            doc_ref.delete()
            raise HTTPException(status_code=400, detail="OTP has expired. Please request a new one.")
            
        if data.get("otp") != request.otp:
            raise HTTPException(status_code=400, detail="Invalid OTP code.")
            
        doc_ref.delete()
        return {"message": "OTP verified successfully", "uid": data.get("uid")}
    except HTTPException:
        raise
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/portfolio/update")
async def update_portfolio(request: PortfolioUpdateRequest):
    try:
        success = AuthService.update_portfolio(request)
        if not success:
            raise HTTPException(status_code=404, detail="Musician not found or invalid type")
        return {"message": "Portfolio updated successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/storage/upload-path")
async def get_upload_path(
    uid: str, 
    file_type: str, 
    filename: Optional[str] = Query(None)
):
    try:
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
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/profile/update")
async def update_profile(request: ProfileUpdateRequest):
    try:
        success = AuthService.update_profile(request)
        if not success:
            raise HTTPException(status_code=404, detail="User not found")
        return {"message": "Profile updated successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/organization/update")
async def update_organization(request: OrganizationUpdateRequest):
    try:
        success = AuthService.update_organization(request)
        if not success:
            raise HTTPException(status_code=404, detail="Organizer not found")
        return {"message": "Organization updated successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/signup/admin")
async def signup_admin(request: AdminSignUpRequest):
    try:
        full_name = f"{request.firstName} {request.lastName}"
        user = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=full_name
        )
        
        user_data = {
            "uid": user.uid,
            "firstName": request.firstName,
            "lastName": request.lastName,
            "name": full_name,
            "email": request.email,
            "role": "super_admin",
            "joinedAt": datetime.now().strftime("%Y-%m-%d"),
            "createdAt": SERVER_TIMESTAMP
        }
        db.collection("admins").document(user.uid).set(user_data)
        
        return {"message": "Super Admin created successfully", "uid": user.uid, "role": "super_admin"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/admin/create-member")
async def create_admin_member(request: CreateAdminMemberRequest):
    try:
        full_name = f"{request.firstName} {request.lastName}"
        user = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=full_name
        )
        
        user_data = {
            "uid": user.uid,
            "firstName": request.firstName,
            "lastName": request.lastName,
            "name": full_name,
            "email": request.email,
            "role": request.role if request.role in ["super_admin", "admin", "support"] else "admin",
            "is2FAEnabled": False,
            "twoFactorMethod": "email",
            "joinedAt": datetime.now().strftime("%Y-%m-%d"),
            "createdAt": SERVER_TIMESTAMP
        }
        db.collection("admins").document(user.uid).set(user_data)
        return {"message": "Team member created successfully", "uid": user.uid, "role": user_data["role"]}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/admin/members")
async def list_admin_members():
    try:
        docs = db.collection("admins").get()
        members: List[Dict[str, Any]] = []
        for doc in docs:
            data: Dict[str, Any] = doc.to_dict() or {}
            members.append({
                "uid": doc.id,
                "name": data.get("name") or f"{data.get('firstName', '')} {data.get('lastName', '')}".strip(),
                "firstName": data.get("firstName", ""),
                "lastName": data.get("lastName", ""),
                "email": data.get("email", ""),
                "role": data.get("role", "super_admin"),
                "is2FAEnabled": bool(data.get("is2FAEnabled", False)),
                "joinedAt": data.get("joinedAt", "")
            })
        return members
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/admin/members/{uid}")
async def delete_admin_member(uid: str):
    try:
        try:
            auth.delete_user(uid)
        except Exception as auth_e:
            print(f"Auth delete error for {uid}: {auth_e}")
            
        db.collection("admins").document(uid).delete()
        return {"message": "Team member deleted successfully", "uid": uid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


def _get_initial_user_status() -> str:
    """
    Returns initial status for newly registered users.
    During Apple Review / onboarding mode, returns 'approved' so reviewers
    can explore the app immediately without waiting for admin approval.
    Can be dynamically toggled via Firestore (collection 'app_settings', doc 'auth', field 'autoApproveUsers')
    or via environment variable AUTO_APPROVE_NEW_USERS.
    """
    try:
        config_doc = db.collection("app_settings").document("auth").get()
        if config_doc.exists:
            val = (config_doc.to_dict() or {}).get("autoApproveUsers")
            if val is not None:
                return "approved" if bool(val) else "pending"
    except Exception as e:
        print(f"Error checking app_settings for autoApproveUsers: {e}")
    
    # Default to auto-approving during review period (True unless explicitly set to false)
    auto_approve = os.getenv("AUTO_APPROVE_NEW_USERS", "true").lower() in ("true", "1", "yes")
    return "approved" if auto_approve else "pending"


@router.post("/signup/musician")
async def signup_musician(request: MusicianSignUpRequest):
    try:
        missing = []
        if not request.fullName or not request.fullName.strip():
            missing.append("Full Name")
        if not request.email or not str(request.email).strip():
            missing.append("Email")
        if not request.bio or not request.bio.strip():
            missing.append("Bio")
        if not request.genres:
            missing.append("Primary Genre")
        if not request.instruments:
            missing.append("Instruments")
        if missing:
            raise HTTPException(
                status_code=422,
                detail=f"Please fill in all required fields: {', '.join(missing)}"
            )

        try:
            existing_user = auth.get_user_by_email(request.email)
            user = auth.update_user(existing_user.uid, display_name=request.fullName)
        except auth.UserNotFoundError:
            user = auth.create_user(
                email=request.email,
                password=request.password,
                display_name=request.fullName
            )
        
        initial_status = _get_initial_user_status()
        user_data = {
            "uid": user.uid,
            "fullName": request.fullName,
            "email": request.email,
            "bio": request.bio,
            "primaryGenre": request.primaryGenre or "",
            "subgenres": request.subgenres or [],
            "tags": request.tags or [],
            "genres": request.genres,
            "instruments": request.instruments,
            "hourlyRate": request.hourlyRate or request.feeRange or 50,
            "feeRange": request.hourlyRate or request.feeRange or 50,
            "yearsOfExperience": request.yearsOfExperience,
            "primaryCity": request.primaryCity or "",
            "primaryState": request.primaryState or "",
            "primaryZip": request.primaryZip or "",
            "secondaryCity": request.secondaryCity or "",
            "secondaryState": request.secondaryState or "",
            "secondaryZip": request.secondaryZip or "",
            "travelRadius": request.travelRadius or 50,
            "location": request.location or (f"{request.primaryCity}, {request.primaryState} {request.primaryZip}".strip() if request.primaryCity else "Not specified"),
            "website": request.website,
            "portfolio": request.portfolio,
            "profileImageUrl": request.profileImageUrl,
            "bannerImageUrl": request.bannerImageUrl,
            "status": initial_status,
            "isProfileCompleted": True,
            "role": "musician",
            "joinedAt": datetime.now().strftime("%Y-%m-%d"),
            "createdAt": SERVER_TIMESTAMP
        }
        db.collection("musicians").document(user.uid).set(user_data, merge=True)
        
        AdminNotificationService.user_activity("New musician registered", f"{request.fullName} ({request.email}) joined as a musician.")
        AdminNotificationService.check_milestones()
        
        return {"message": "Musician created successfully", "uid": user.uid, "status": initial_status}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/signup")
async def signup(request: SignUpRequest):
    try:
        missing = []
        if not request.name or not request.name.strip():
            missing.append("Name")
        if not request.orgName or not request.orgName.strip():
            missing.append("Organization Name")
        if not request.email or not str(request.email).strip():
            missing.append("Email")
        if not request.type or not request.type.strip():
            missing.append("Organizer Type")
        if not request.contact or not request.contact.strip():
            missing.append("Contact Phone")
        if not request.location or not request.location.strip():
            missing.append("Location")
        if not request.bio or not request.bio.strip():
            missing.append("Bio")
        if missing:
            raise HTTPException(
                status_code=422,
                detail=f"Please fill in all required fields: {', '.join(missing)}"
            )

        try:
            existing_user = auth.get_user_by_email(request.email)
            user = auth.update_user(existing_user.uid, display_name=request.name)
        except auth.UserNotFoundError:
            user = auth.create_user(
                email=request.email,
                password=request.password,
                display_name=request.name
            )
        
        initial_status = _get_initial_user_status()
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
            "status": initial_status,
            "isProfileCompleted": True,
            "role": "organizer",
            "joinedAt": datetime.now().strftime("%Y-%m-%d"),
            "createdAt": SERVER_TIMESTAMP
        }
        db.collection("organizers").document(user.uid).set(user_data, merge=True)
        
        AdminNotificationService.user_activity("New organizer registered", f"{request.name} ({request.email}) joined as an organizer.")
        AdminNotificationService.check_milestones()
        
        return {"message": "User created successfully", "uid": user.uid, "status": initial_status}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/password/update")
async def update_password(request: PasswordUpdateRequest):
    try:
        success = AuthService.update_password(request)
        if not success:
            raise HTTPException(status_code=400, detail="Failed to update password")
        return {"message": "Password updated successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/user/status")
async def update_user_status(request: UserStatusRequest):
    try:
        success = AuthService.update_user_status(request)
        if not success:
            raise HTTPException(status_code=400, detail="Failed to update user status")
        return {"message": f"User status updated to {request.status} successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class BulkUserStatusRequest(BaseModel):
    userIds: List[str]
    status: str
    userType: Optional[str] = None


class BulkUserDeleteRequest(BaseModel):
    userIds: List[str]
    userType: Optional[str] = None


@router.post("/users/bulk-status")
async def bulk_update_user_status(request: BulkUserStatusRequest):
    try:
        res = AuthService.update_users_status_batch(request.userIds, request.status, request.userType)
        return res
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/users/bulk-delete")
async def bulk_delete_users(request: BulkUserDeleteRequest):
    try:
        res = AuthService.delete_users_batch(request.userIds, request.userType)
        return res
    except Exception as e:
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
            err_msg = data["error"].get("message", "Sign in failed") if isinstance(data["error"], dict) else str(data["error"])
            if "TOO_MANY_ATTEMPTS" in err_msg:
                raise HTTPException(
                    status_code=429,
                    detail="Too many attempts. Please wait a few minutes before trying again."
                )
            if "INVALID_PASSWORD" in err_msg or "INVALID_LOGIN_CREDENTIALS" in err_msg:
                raise HTTPException(status_code=401, detail="Invalid email or password.")
            if "EMAIL_NOT_FOUND" in err_msg:
                raise HTTPException(status_code=401, detail="No account found with this email address.")
            raise HTTPException(status_code=401, detail=err_msg.replace("_", " "))
        
        uid = data["localId"]
        profile = AuthService.get_profile(uid)
        role = profile["role"] if profile else "unknown"
        display_name = profile.get("name") or profile.get("fullName") if profile else "User"
        profile_image = profile.get("profileImageUrl") if profile else None
        
        action = "Admin login" if role == "admin" else f"{role.capitalize()} login"
        SecurityService.create_log(action, request.email)
        
        is_2fa_enabled = profile.get("is2FAEnabled") if profile else False
        phone_number = profile.get("phoneNumber") if profile else None
        two_factor_method = profile.get("twoFactorMethod") if profile else None
        
        two_factor_method_frontend = None
        if two_factor_method == "email":
            two_factor_method_frontend = "email_link"
        elif two_factor_method == "sms":
            two_factor_method_frontend = "sms"
        
        user_status = profile.get("status", "pending_approval") if profile else "pending_approval"
        
        return {
            "idToken": data["idToken"],
            "email": data["email"],
            "localId": uid,
            "role": role,
            "displayName": display_name,
            "profileImageUrl": profile_image,
            "is2FAEnabled": is_2fa_enabled,
            "phoneNumber": phone_number,
            "twoFactorMethod": two_factor_method_frontend,
            "status": user_status
        }
    except HTTPException:
        raise
    except Exception as e:
        SecurityService.create_log("Failed login attempt", request.email, status="failed")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/create-user")
async def create_user(request: CreateUserRequest):
    try:
        user = auth.create_user(email=request.email, password=request.password)
        return {"uid": user.uid, "email": user.email}
    except auth.EmailAlreadyExistsError:
        # User already exists in Firebase Auth — handle gracefully
        existing = auth.get_user_by_email(request.email)
        if existing.email_verified:
            # Verified account: ask them to sign in instead
            raise HTTPException(
                status_code=409,
                detail="An account with this email already exists. Please sign in instead."
            )
        else:
            # Unverified account: sign them back in so they can re-receive the verification email
            signin_data = _firebase_auth_request("accounts:signInWithPassword", {
                "email": request.email,
                "password": request.password,
                "returnSecureToken": True,
            })
            if "error" in signin_data:
                # Wrong password or other error — tell them account exists
                raise HTTPException(
                    status_code=409,
                    detail="An account with this email already exists. Please sign in instead."
                )
            return {
                "uid": existing.uid,
                "email": existing.email,
                "id_token": signin_data.get("idToken"),
                "status": "existing_unverified"
            }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e).replace("_", " "))


@router.post("/send-verification-email")
async def send_verification_email(request: SendVerificationRequest):
    try:
        data = _firebase_auth_request("accounts:sendOobCode", {
            "requestType": "VERIFY_EMAIL",
            "idToken": request.id_token,
        })
        if "error" in data:
            err_msg = data["error"].get("message", "Failed to send verification email") if isinstance(data["error"], dict) else str(data["error"])
            if "TOO_MANY_ATTEMPTS" in err_msg or "RESET_PASSWORD_EXCEED_LIMIT" in err_msg:
                # Google throttles if an email was already dispatched recently to this user.
                # Treat as success because the verification email is already in the user's inbox.
                return {"message": "Verification email already sent to your inbox", "status": "already_sent"}
            raise HTTPException(status_code=400, detail=err_msg.replace("_", " "))
        return {"message": "Verification email sent"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/check-email-verification")
async def check_email_verification(request: CheckVerificationRequest):
    try:
        user = auth.get_user(request.uid)
        return {"email_verified": user.email_verified}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/2fa/enable")
async def enable_2fa(request: Enable2FARequest):
    try:
        collection_map = {
            "musician": "musicians",
            "organizer": "organizers",
            "admin": "admins"
        }
        collection = collection_map.get(request.userType, "organizers")
        
        db.collection(collection).document(request.uid).set(
            {
                "is2FAEnabled": request.enabled,
                "updated_at": datetime.now(timezone.utc),
            },
            merge=True
        )
        
        return {
            "message": f"2FA {'enabled' if request.enabled else 'disabled'} successfully",
            "is2FAEnabled": request.enabled
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/2fa/set-method")
async def set_2fa_method(request: Set2FAMethodRequest):
    try:
        if request.method not in ['sms', 'email']:
            raise HTTPException(status_code=400, detail="Method must be 'sms' or 'email'")
        
        collection_map = {
            "musician": "musicians",
            "organizer": "organizers",
            "admin": "admins"
        }
        collection = collection_map.get(request.userType, "organizers")
        
        db.collection(collection).document(request.uid).set(
            {
                "twoFactorMethod": request.method,
                "updated_at": datetime.now(timezone.utc),
            },
            merge=True
        )
        
        return {
            "message": f"2FA method set to {request.method}",
            "twoFactorMethod": request.method
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/2fa/save-phone")
async def save_phone_number(request: SavePhoneNumberRequest):
    try:
        if not request.phoneNumber or len(request.phoneNumber) < 10:
            raise HTTPException(status_code=400, detail="Invalid phone number format")
        
        collection_map = {
            "musician": "musicians",
            "organizer": "organizers",
            "admin": "admins"
        }
        collection = collection_map.get(request.userType, "organizers")
        
        db.collection(collection).document(request.uid).set(
            {
                "phoneNumber": request.phoneNumber,
                "updated_at": datetime.now(timezone.utc),
            },
            merge=True
        )
        
        return {
            "message": "Phone number saved successfully",
            "phoneNumber": request.phoneNumber
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/send-email-link-2fa")
async def send_email_link_2fa(request: SendEmailLink2FARequest):
    try:
        continue_url = request.continueUrl if request.continueUrl else "http://localhost:3000/verify-2fa-link"
        data = _firebase_auth_request("accounts:sendOobCode", {
            "requestType": "EMAIL_SIGNIN",
            "email": request.email,
            "continueUrl": continue_url,
            "canHandleCodeInApp": True,
        })
        if "error" in data:
            err_msg = data["error"].get("message", "Failed to send email link") if isinstance(data["error"], dict) else str(data["error"])
            raise HTTPException(status_code=400, detail=err_msg)
        return {"message": "Email verification link sent successfully", "email": request.email}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/export-data")
async def export_user_data(uid: str):
    try:
        user_data = None
        user_collection = None
        for col in ["admins", "musicians", "organizers"]:
            doc: Any = db.collection(col).document(uid).get()
            if doc.exists:
                user_data = doc.to_dict() or {}
                user_collection = col
                break
        
        if not user_data:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_email = user_data.get("email", "")
        logs = []
        if user_email:
            try:
                log_docs = db.collection("security_logs").where("email", "==", user_email).get()
                for ldoc in log_docs:
                    ldata = ldoc.to_dict() or {}
                    logs.append({
                        "action": ldata.get("action"),
                        "timestamp": str(ldata.get("createdAt")),
                        "status": ldata.get("status")
                    })
            except Exception:
                pass

        return {
            "account": {
                "uid": uid,
                "collection": user_collection,
                "profile": user_data,
                "exportedAt": datetime.now(timezone.utc).isoformat()
            },
            "securityLogs": logs
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/delete-account")
async def delete_account(request: DeleteAccountRequest):
    try:
        user_data = None
        user_role = None

        for col in ["musicians", "organizers", "admins"]:
            doc_ref = db.collection(col).document(request.uid)
            doc: Any = doc_ref.get()
            if getattr(doc, "exists", False) or (hasattr(doc, "exists") and doc.exists):
                user_data = doc.to_dict()
                user_role = col
                # Create safety audit archive in deleted_users collection
                db.collection("deleted_users").document(request.uid).set({
                    "uid": request.uid,
                    "originalRole": user_role,
                    "profileArchive": user_data,
                    "deletedAt": datetime.now().isoformat(),
                    "status": "DELETED_COMPLIANT_ARCHIVE",
                })
                # Delete active public profile
                doc_ref.delete()
                break

        # Delete Firebase Auth user credentials
        try:
            auth.delete_user(request.uid)
        except Exception as auth_err:
            print(f"Auth user delete warning: {auth_err}")

        return {"message": "Account permanently deleted and archived for compliance", "success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def _compile_user_export(uid: str) -> dict:
    user_data = None
    user_role = None
    for col in ["musicians", "organizers", "admins", "users"]:
        doc_ref = db.collection(col).document(uid)
        doc: Any = doc_ref.get()
        if getattr(doc, "exists", False) or (hasattr(doc, "exists") and doc.exists):
            user_data = doc.to_dict()
            user_role = col
            break

    if not user_data:
        # Check deleted_users archive
        del_doc: Any = db.collection("deleted_users").document(uid).get()
        if getattr(del_doc, "exists", False) or (hasattr(del_doc, "exists") and del_doc.exists):
            archive_dict = del_doc.to_dict() or {}
            user_data = archive_dict.get("profileArchive", {})
            user_role = archive_dict.get("originalRole", "user")
        else:
            raise HTTPException(status_code=404, detail="User profile not found")

    # 1. Fetch Gigs
    gigs = []
    if user_role == "organizer":
        gig_docs = db.collection("gigs").where("organizerId", "==", uid).stream()
        gigs = [g.to_dict() for g in gig_docs if g.to_dict() is not None]

    # 2. Fetch Applications
    applications = []
    if user_role == "musician":
        app_docs = db.collection("applications").where("musicianId", "==", uid).stream()
        applications = [a.to_dict() for a in app_docs if a.to_dict() is not None]
    elif user_role == "organizer":
        app_docs = db.collection("applications").where("organizerId", "==", uid).stream()
        applications = [a.to_dict() for a in app_docs if a.to_dict() is not None]

    # 3. Fetch Bookings
    bookings = []
    booking_query_col = "musicianId" if user_role == "musician" else "organizerId"
    b_docs = db.collection("bookings").where(booking_query_col, "==", uid).stream()
    bookings = [b.to_dict() for b in b_docs if b.to_dict() is not None]

    # 4. Fetch Chats & Messages
    chats = []
    chat_docs = db.collection("chats").stream()
    for c in chat_docs:
        cd = c.to_dict()
        if cd is not None:
            participants = cd.get("participants", [])
            if uid in participants or cd.get("musicianId") == uid or cd.get("organizerId") == uid:
                msg_docs = c.reference.collection("messages").stream()
                cd["messages"] = [m.to_dict() for m in msg_docs if m.to_dict() is not None]
                chats.append(cd)

    # 5. Fetch Transactions / Payments
    transactions = []
    tx_docs = db.collection("transactions").stream()
    for tx in tx_docs:
        txd = tx.to_dict()
        if txd is not None:
            if txd.get("userId") == uid or txd.get("musicianId") == uid or txd.get("organizerId") == uid:
                transactions.append(txd)

    # 6. Fetch Notifications
    notifications = []
    notif_docs = db.collection("notifications").where("userId", "==", uid).stream()
    notifications = [n.to_dict() for n in notif_docs if n.to_dict() is not None]

    # 7. Fetch Reviews
    reviews = []
    rev_docs = db.collection("reviews").stream()
    for r in rev_docs:
        rd = r.to_dict()
        if rd is not None:
            if rd.get("authorId") == uid or rd.get("targetUserId") == uid or rd.get("musicianId") == uid or rd.get("organizerId") == uid:
                reviews.append(rd)

    return {
        "success": True,
        "exportDate": datetime.now().isoformat(),
        "userId": uid,
        "role": user_role,
        "profile": user_data,
        "gigs": gigs,
        "applications": applications,
        "bookings": bookings,
        "chatsAndMessages": chats,
        "transactions": transactions,
        "notifications": notifications,
        "reviews": reviews,
    }


def _generate_export_html(data: dict) -> str:
    profile = data.get("profile") or {}
    name = profile.get("fullName") or profile.get("name") or "OnlyGigz User"
    email = profile.get("email", "Not provided")
    phone = profile.get("phoneNumber") or profile.get("phone", "Not provided")
    location = profile.get("location") or profile.get("city", "Not specified")
    bio = profile.get("bio", "No bio provided.")
    role = data.get("role", "user").capitalize()
    export_date = data.get("exportDate", "")

    genres = profile.get("genres", [])
    genres_html = "".join(f"<span class='badge'>{g}</span> " for g in genres) if genres else "None"

    # Applications table rows
    apps = data.get("applications", [])
    apps_rows = ""
    for a in apps:
        gig_title = a.get("gigTitle", a.get("title", "Gig Application"))
        status = a.get("status", "pending")
        loc = a.get("location", "N/A")
        date = str(a.get("createdAt", ""))[:10]
        apps_rows += f"<tr><td>{gig_title}</td><td><span class='badge'>{status}</span></td><td>{loc}</td><td>{date}</td></tr>"
    if not apps_rows:
        apps_rows = "<tr><td colspan='4' style='color:#888;'>No applications on record.</td></tr>"

    # Bookings table rows
    bookings = data.get("bookings", [])
    bookings_rows = ""
    for b in bookings:
        title = b.get("gigTitle", b.get("title", "Booking"))
        status = b.get("status", "confirmed")
        date = b.get("gigDate", b.get("date", "N/A"))
        rate = f"${b.get('proposedRate', b.get('rate', 0))}"
        bookings_rows += f"<tr><td>{title}</td><td><span class='badge'>{status}</span></td><td>{rate}</td><td>{date}</td></tr>"
    if not bookings_rows:
        bookings_rows = "<tr><td colspan='4' style='color:#888;'>No bookings on record.</td></tr>"

    # Transactions table rows
    txs = data.get("transactions", [])
    tx_rows = ""
    for t in txs:
        desc = t.get("description", t.get("type", "Payment"))
        amt = f"${t.get('amount', 0)}"
        status = t.get("status", "completed")
        date = str(t.get("createdAt", ""))[:10]
        tx_rows += f"<tr><td>{desc}</td><td>{amt}</td><td><span class='badge'>{status}</span></td><td>{date}</td></tr>"
    if not tx_rows:
        tx_rows = "<tr><td colspan='4' style='color:#888;'>No transactions on record.</td></tr>"

    # Portfolio list
    portfolio = profile.get("portfolio") or {}
    portfolio_html = ""
    if isinstance(portfolio, dict):
        for media_type, items in portfolio.items():
            if isinstance(items, list) and items:
                portfolio_html += f"<h3 style='color:#A1F301;margin-top:14px;'>{media_type.capitalize()} ({len(items)})</h3><ul>"
                for item in items:
                    url = item.get("url") if isinstance(item, dict) else str(item)
                    title = item.get("title", "File") if isinstance(item, dict) else "File"
                    portfolio_html += f"<li><strong>{title}</strong>: <a href='{url}' target='_blank'>{url}</a></li>"
                portfolio_html += "</ul>"
    if not portfolio_html:
        portfolio_html = "<p style='color:#888;'>No uploaded portfolio files on record.</p>"

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>OnlyGigz Complete Data Archive - {name}</title>
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background: #0A0A0F; color: #E5E5E5; margin: 0; padding: 36px; line-height: 1.6; }}
    .container {{ max-width: 900px; margin: 0 auto; }}
    .header {{ border-bottom: 2px solid #A1F301; padding-bottom: 20px; margin-bottom: 30px; }}
    h1 {{ color: #A1F301; margin: 0 0 6px 0; font-size: 28px; }}
    h2 {{ color: #A1F301; margin: 28px 0 14px 0; font-size: 20px; border-bottom: 1px solid #222228; padding-bottom: 6px; }}
    .meta {{ color: #888888; font-size: 13px; }}
    .card {{ background: #16161C; border: 1px solid #282830; border-radius: 12px; padding: 20px; margin-bottom: 20px; }}
    .grid {{ display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }}
    .label {{ color: #888888; font-size: 12px; text-transform: uppercase; margin-bottom: 2px; }}
    .value {{ font-size: 15px; font-weight: 500; color: #FFFFFF; }}
    table {{ width: 100%; border-collapse: collapse; margin-top: 10px; }}
    th, td {{ text-align: left; padding: 10px 14px; border-bottom: 1px solid #222228; font-size: 13px; }}
    th {{ background: #111116; color: #A1F301; font-weight: 600; }}
    .badge {{ display: inline-block; padding: 3px 8px; border-radius: 6px; font-size: 11px; font-weight: bold; background: rgba(161, 243, 1, 0.15); color: #A1F301; border: 1px solid rgba(161, 243, 1, 0.3); }}
    a {{ color: #06B6D4; text-decoration: none; word-break: break-all; }}
    a:hover {{ text-decoration: underline; }}
    .footer {{ margin-top: 40px; padding-top: 16px; border-top: 1px solid #222228; text-align: center; color: #666666; font-size: 12px; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>ONLYGIGZ &mdash; Account Data Archive</h1>
      <div class="meta">Export generated on {export_date} &bull; Account Role: {role}</div>
    </div>

    <h2>1. Profile Information</h2>
    <div class="card">
      <div class="grid">
        <div><div class="label">Full Name</div><div class="value">{name}</div></div>
        <div><div class="label">Role</div><div class="value">{role}</div></div>
        <div><div class="label">Email Address</div><div class="value">{email}</div></div>
        <div><div class="label">Phone Number</div><div class="value">{phone}</div></div>
        <div><div class="label">Location</div><div class="value">{location}</div></div>
        <div><div class="label">Genres</div><div class="value">{genres_html}</div></div>
      </div>
      <div style="margin-top: 16px;">
        <div class="label">Biography</div>
        <div class="value" style="font-size: 14px; color: #CCCCCC; margin-top: 4px;">{bio}</div>
      </div>
    </div>

    <h2>2. Portfolio & Uploaded Media Files</h2>
    <div class="card">
      <p style="color:#AAA;font-size:13px;margin-top:0;">All direct files and references stored in your OnlyGigz portfolio. Downloaded media files are also included in the <code>portfolio/</code> directory of this ZIP archive.</p>
      {portfolio_html}
    </div>

    <h2>3. Applications History ({len(apps)})</h2>
    <div class="card" style="padding: 0; overflow: hidden;">
      <table>
        <thead><tr><th>Gig Title</th><th>Status</th><th>Location</th><th>Date</th></tr></thead>
        <tbody>{apps_rows}</tbody>
      </table>
    </div>

    <h2>4. Bookings & Contracts ({len(bookings)})</h2>
    <div class="card" style="padding: 0; overflow: hidden;">
      <table>
        <thead><tr><th>Booking Title</th><th>Status</th><th>Agreed Rate</th><th>Date</th></tr></thead>
        <tbody>{bookings_rows}</tbody>
      </table>
    </div>

    <h2>5. Transactions & Invoices ({len(txs)})</h2>
    <div class="card" style="padding: 0; overflow: hidden;">
      <table>
        <thead><tr><th>Description</th><th>Amount</th><th>Status</th><th>Date</th></tr></thead>
        <tbody>{tx_rows}</tbody>
      </table>
    </div>

    <div class="footer">
      This archive was created pursuant to your OnlyGigz Privacy & Data Portability request. &copy; OnlyGigz.
    </div>
  </div>
</body>
</html>"""


@router.post("/export-data")
async def export_data(request: ExportDataRequest):
    try:
        data = _compile_user_export(request.uid)
        return data
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/download-data/{uid}")
@router.post("/download-data/{uid}")
async def download_data_archive(uid: str):
    try:
        data = _compile_user_export(uid)
        profile = data.get("profile") or {}
        raw_name = profile.get("fullName") or profile.get("name") or uid
        clean_name = re.sub(r'[^a-zA-Z0-9_-]', '_', raw_name)

        # Build in-memory ZIP
        zip_buf = io.BytesIO()
        with zipfile.ZipFile(zip_buf, "w", zipfile.ZIP_DEFLATED) as zf:
            # 1. HTML Summary
            html_content = _generate_export_html(data)
            zf.writestr("account_summary.html", html_content)

            # 2. JSON files with default=str to avoid serialization issues
            zf.writestr("profile.json", _json.dumps(profile, default=str, indent=2))
            zf.writestr("applications.json", _json.dumps(data.get("applications", []), default=str, indent=2))
            zf.writestr("bookings.json", _json.dumps(data.get("bookings", []), default=str, indent=2))
            zf.writestr("transactions.json", _json.dumps(data.get("transactions", []), default=str, indent=2))
            zf.writestr("chats_and_messages.json", _json.dumps(data.get("chatsAndMessages", []), default=str, indent=2))
            zf.writestr("reviews.json", _json.dumps(data.get("reviews", []), default=str, indent=2))
            zf.writestr("notifications.json", _json.dumps(data.get("notifications", []), default=str, indent=2))

            # 3. Portfolio & Media Files
            portfolio_manifest = []
            portfolio = profile.get("portfolio") or {}
            media_urls = []

            # Profile and cover images
            if profile.get("profileImageUrl"):
                media_urls.append(("profile_image", profile["profileImageUrl"]))
            if profile.get("bannerImageUrl"):
                media_urls.append(("banner_image", profile["bannerImageUrl"]))

            # Extract portfolio items
            if isinstance(portfolio, dict):
                for mtype in ["images", "photos", "audio", "audioTracks", "videos"]:
                    items = portfolio.get(mtype) or []
                    if isinstance(items, list):
                        for idx, it in enumerate(items):
                            url = it.get("url") if isinstance(it, dict) else str(it)
                            title = it.get("title", f"{mtype}_{idx+1}") if isinstance(it, dict) else f"{mtype}_{idx+1}"
                            if url and url.startswith("http"):
                                media_urls.append((f"{mtype}/{title}", url))

            # Attempt to download media files (with 4s timeout each, max 10 files)
            for label, url in media_urls[:10]:
                try:
                    ext = ".jpg"
                    if ".png" in url.lower(): ext = ".png"
                    elif ".mp3" in url.lower(): ext = ".mp3"
                    elif ".wav" in url.lower(): ext = ".wav"
                    elif ".mp4" in url.lower(): ext = ".mp4"
                    
                    clean_label = re.sub(r'[^a-zA-Z0-9_\-/]', '_', label)
                    filename = f"portfolio/{clean_label}{ext}"
                    
                    req = urllib.request.Request(url, headers={'User-Agent': 'OnlyGigzExport/1.0'})
                    with urllib.request.urlopen(req, timeout=4) as response:
                        content = response.read(15 * 1024 * 1024) # max 15MB per file
                        zf.writestr(filename, content)
                        portfolio_manifest.append(f"SUCCESS: {label} -> {filename} ({len(content)} bytes)")
                except Exception as dl_err:
                    portfolio_manifest.append(f"LINK_ONLY: {label} -> {url} (Download note: {dl_err})")

            # Write manifest
            zf.writestr("portfolio/portfolio_manifest.txt", "\n".join(portfolio_manifest) if portfolio_manifest else "No portfolio media files.")

        zip_bytes = zip_buf.getvalue()

        return Response(
            content=zip_bytes,
            media_type="application/zip",
            headers={
                "Content-Disposition": f'attachment; filename="OnlyGigz_Data_Export_{clean_name}.zip"',
                "Content-Length": str(len(zip_bytes)),
            }
        )
    except HTTPException:
        raise
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/send-approval-email")
async def send_approval_email(request: SendApprovalEmailRequest):
    try:
        success = EmailService.send_account_approved_email(
            to_email=request.email,
            user_name=request.name or "User"
        )
        if not success:
            raise HTTPException(status_code=500, detail="Failed to send approval email via SendGrid")
        return {
            "success": True,
            "message": f"Account approval email successfully sent to {request.email}"
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class SendGridConfigUpdateRequest(BaseModel):
    sendgrid_api_key: str
    from_email: Optional[str] = "notifications@onlygigz.app"


@router.get("/sendgrid-config")
async def get_sendgrid_config():
    try:
        doc: Any = db.collection("system_config").document("email").get()
        data: Dict[str, Any] = (doc.to_dict() if getattr(doc, "exists", False) else {}) or {}
        key = data.get("sendgrid_api_key") or os.getenv("SENDGRID_API_KEY") or os.getenv("TWILIO_SENDGRID_API_KEY") or ""
        masked_key = f"{key[:6]}...{key[-4:]}" if len(key) > 10 else ("Configured" if key else "Not Configured")
        return {
            "configured": bool(key),
            "masked_key": masked_key,
            "from_email": data.get("from_email") or os.getenv("SENDGRID_FROM_EMAIL") or "notifications@onlygigz.app"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/sendgrid-config")
async def update_sendgrid_config(req: SendGridConfigUpdateRequest):
    try:
        db.collection("system_config").document("email").set({
            "sendgrid_api_key": req.sendgrid_api_key.strip(),
            "from_email": req.from_email.strip() if req.from_email else "notifications@onlygigz.app",
            "updatedAt": SERVER_TIMESTAMP
        }, merge=True)
        return {"message": "Twilio SendGrid API Key saved successfully to Firebase!"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


