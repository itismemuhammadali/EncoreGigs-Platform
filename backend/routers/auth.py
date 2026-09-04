import os
import secrets
import smtplib
import urllib3
import json as _json
import traceback
from datetime import datetime, timedelta, timezone
from typing import Optional, List, Dict, Any

from fastapi import APIRouter, HTTPException, Query, File, UploadFile
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
    if request.role:
        collection_name = (
            "musicians"
            if request.role == "musician"
            else ("organizers" if request.role == "organizer" else f"{request.role}s")
        )
        docs = db.collection(collection_name).where("email", "==", request.email.lower()).limit(1).get()
        if not docs:
            docs = db.collection(collection_name).where("email", "==", request.email).limit(1).get()
        if not docs:
            raise HTTPException(status_code=400, detail="No account found with this email address.")

    payload = {
        "requestType": "PASSWORD_RESET",
        "email": request.email
    }
    
    try:
        data = _firebase_auth_request("accounts:sendOobCode", payload)
        
        if "error" in data:
            err_msg = data["error"].get("message", "Failed to send password reset email") if isinstance(data["error"], dict) else str(data["error"])
            raise HTTPException(status_code=400, detail=err_msg)
            
        SecurityService.create_log("Password reset requested", request.email)
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


@router.post("/signup/musician")
async def signup_musician(request: MusicianSignUpRequest):
    try:
        try:
            existing_user = auth.get_user_by_email(request.email)
            user = auth.update_user(existing_user.uid, display_name=request.fullName)
        except auth.UserNotFoundError:
            user = auth.create_user(
                email=request.email,
                password=request.password,
                display_name=request.fullName
            )
        
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
            "status": "pending",
            "role": "musician",
            "joinedAt": datetime.now().strftime("%Y-%m-%d"),
            "createdAt": SERVER_TIMESTAMP
        }
        db.collection("musicians").document(user.uid).set(user_data)
        
        AdminNotificationService.user_activity("New musician registered", f"{request.fullName} ({request.email}) joined as a musician.")
        AdminNotificationService.check_milestones()
        
        return {"message": "Musician created successfully", "uid": user.uid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/signup")
async def signup(request: SignUpRequest):
    try:
        try:
            existing_user = auth.get_user_by_email(request.email)
            user = auth.update_user(existing_user.uid, display_name=request.name)
        except auth.UserNotFoundError:
            user = auth.create_user(
                email=request.email,
                password=request.password,
                display_name=request.name
            )
        
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
            "createdAt": SERVER_TIMESTAMP
        }
        db.collection("organizers").document(user.uid).set(user_data)
        
        AdminNotificationService.user_activity("New organizer registered", f"{request.name} ({request.email}) joined as an organizer.")
        AdminNotificationService.check_milestones()
        
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
            raise HTTPException(status_code=401, detail=err_msg)
        
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
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/send-verification-email")
async def send_verification_email(request: SendVerificationRequest):
    try:
        data = _firebase_auth_request("accounts:sendOobCode", {
            "requestType": "VERIFY_EMAIL",
            "idToken": request.id_token,
        })
        if "error" in data:
            err_msg = data["error"].get("message", "Failed to send verification email") if isinstance(data["error"], dict) else str(data["error"])
            raise HTTPException(status_code=400, detail=err_msg)
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


@router.post("/export-data")
async def export_data(request: ExportDataRequest):
    try:
        user_data = None
        user_role = None
        for col in ["musicians", "organizers", "admins"]:
            doc_ref = db.collection(col).document(request.uid)
            doc: Any = doc_ref.get()
            if getattr(doc, "exists", False) or (hasattr(doc, "exists") and doc.exists):
                user_data = doc.to_dict()
                user_role = col
                break

        if not user_data:
            # Check deleted_users archive
            del_doc: Any = db.collection("deleted_users").document(request.uid).get()
            if getattr(del_doc, "exists", False) or (hasattr(del_doc, "exists") and del_doc.exists):
                archive_dict = del_doc.to_dict() or {}
                user_data = archive_dict.get("profileArchive", {})
                user_role = archive_dict.get("originalRole", "user")
            else:
                raise HTTPException(status_code=404, detail="User profile not found")

        # 1. Fetch Gigs
        gigs = []
        if user_role == "organizer":
            gig_docs = db.collection("gigs").where("organizerId", "==", request.uid).stream()
            gigs = [g.to_dict() for g in gig_docs if g.to_dict() is not None]

        # 2. Fetch Applications
        applications = []
        if user_role == "musician":
            app_docs = db.collection("applications").where("musicianId", "==", request.uid).stream()
            applications = [a.to_dict() for a in app_docs if a.to_dict() is not None]
        elif user_role == "organizer":
            app_docs = db.collection("applications").where("organizerId", "==", request.uid).stream()
            applications = [a.to_dict() for a in app_docs if a.to_dict() is not None]

        # 3. Fetch Bookings
        bookings = []
        booking_query_col = "musicianId" if user_role == "musician" else "organizerId"
        b_docs = db.collection("bookings").where(booking_query_col, "==", request.uid).stream()
        bookings = [b.to_dict() for b in b_docs if b.to_dict() is not None]

        # 4. Fetch Chats & Messages
        chats = []
        chat_docs = db.collection("chats").stream()
        for c in chat_docs:
            cd = c.to_dict()
            if cd is not None:
                participants = cd.get("participants", [])
                if request.uid in participants or cd.get("musicianId") == request.uid or cd.get("organizerId") == request.uid:
                    # Fetch subcollection messages
                    msg_docs = c.reference.collection("messages").stream()
                    cd["messages"] = [m.to_dict() for m in msg_docs if m.to_dict() is not None]
                    chats.append(cd)

        # 5. Fetch Transactions / Payments
        transactions = []
        tx_docs = db.collection("transactions").stream()
        for tx in tx_docs:
            txd = tx.to_dict()
            if txd is not None:
                if txd.get("userId") == request.uid or txd.get("musicianId") == request.uid or txd.get("organizerId") == request.uid:
                    transactions.append(txd)

        # 6. Fetch Notifications
        notifications = []
        notif_docs = db.collection("notifications").where("userId", "==", request.uid).stream()
        notifications = [n.to_dict() for n in notif_docs if n.to_dict() is not None]

        # 7. Fetch Reviews
        reviews = []
        rev_docs = db.collection("reviews").stream()
        for r in rev_docs:
            rd = r.to_dict()
            if rd is not None:
                if rd.get("authorId") == request.uid or rd.get("targetUserId") == request.uid or rd.get("musicianId") == request.uid or rd.get("organizerId") == request.uid:
                    reviews.append(rd)

        return {
            "success": True,
            "exportDate": datetime.now().isoformat(),
            "userId": request.uid,
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
    except HTTPException:
        raise
    except Exception as e:
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
        doc = db.collection("system_config").document("email").get()
        data = doc.to_dict() if doc.exists else {}
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


