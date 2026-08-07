from fastapi import APIRouter, HTTPException, Query, File, UploadFile
from typing import Optional, List, Dict, Any
from pydantic import BaseModel
from firebase_admin import auth, firestore
from google.cloud.firestore import SERVER_TIMESTAMP
import urllib3
import json as _json
from backend.services.auth_service import AuthService
from backend.services.storage_service import StorageService
from backend.services.security_service import SecurityService
from backend.models.auth_models import SignUpRequest, SignInRequest, ProfileUpdateRequest, OrganizationUpdateRequest, AdminSignUpRequest, ForgotPasswordRequest, PasswordUpdateRequest, UserStatusRequest, SendEmailOTPRequest, VerifyEmailOTPRequest, Enable2FARequest, Set2FAMethodRequest, SavePhoneNumberRequest, SendEmailLink2FARequest, CreateAdminMemberRequest
from backend.models.musician_models import MusicianSignUpRequest, PortfolioUpdateRequest
import random
import smtplib
import secrets
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta, timezone
import os
from fastapi import APIRouter, HTTPException, UploadFile, File, Query

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
        path = StorageService.get_upload_path(uid, file_type, file.filename or "file")
        public_url = StorageService.upload_file(content, path, file.content_type or "image/jpeg")
        
        # Automatically update database if it's a profile photo
        if file_type == "profile_photo":
            try:
                from backend.database import db
                print(f"DEBUG: Updating Firestore for UID: {uid}")
                # Check which collection the user is in
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

def _send_otp_email(to_email: str, otp_code: str, uid: Optional[str] = None):
    """
    Send an OTP code via email using Resend transactional email service.
    
    Replaces Gmail SMTP with Resend for reliability and easy sandbox mode testing.
    - In sandbox: sends only to account owner's registered email
    - In production: sends to any verified domain recipient
    
    Args:
        to_email: Recipient email address
        otp_code: 6-digit OTP code or email link
        uid: Optional user ID for logging
        
    Returns:
        True if email sent successfully, raises exception on failure
    """
    try:
        # Get Resend API key from environment FIRST
        resend_api_key = os.getenv("RESEND_API_KEY")
        
        # DEV MODE: No API key set, just print the code/link
        if not resend_api_key or "your_resend_api_key" in resend_api_key:
            print(f"\n{'='*60}")
            print(f"🔑 [DEV MODE] VERIFICATION EMAIL LINK / OTP FOR {to_email}:")
            print(f"{'='*60}")
            print(f"{otp_code}")
            print(f"{'='*60}\n")
            return True
        
        # PRODUCTION: Import Resend and send actual email
        import resend as _resend  # type: ignore
        resend: Any = _resend
        resend.api_key = resend_api_key
        
        # HTML email template
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
        
        # Send via Resend
        response = resend.Emails.send({
            "from": "onboarding@resend.dev",  # Sandbox mode sender
            "to": to_email,
            "subject": "OnlyGigz - Your Verification Code",
            "html": html_body
        })
        
        print(f"\n{'='*60}")
        print(f"📧 OTP EMAIL SENT")
        print(f"{'='*60}")
        print(f"To: {to_email}")
        print(f"OTP Code: {otp_code}")
        print(f"Expires: 10 minutes")
        print(f"{'='*60}\n")
        
        return True
        
    except ValueError as e:
        # Missing API key
        print(f"\n{'='*60}")
        print(f"⚠️  RESEND CONFIGURATION ERROR")
        print(f"{'='*60}")
        print(str(e))
        print(f"{'='*60}\n")
        raise
    except Exception as e:
        # Resend API error or network issue
        print(f"\n{'='*60}")
        print(f"❌ RESEND EMAIL FAILED")
        print(f"{'='*60}")
        print(f"Error: {e}")
        print(f"{'='*60}\n")
        raise

@router.post("/send-email-otp")
async def send_email_otp(request: SendEmailOTPRequest):
    try:
        from firebase_admin import auth
        from backend.database import db
        
        print(f"\n{'='*70}")
        print(f"🔷 SEND EMAIL OTP ENDPOINT CALLED")
        print(f"{'='*70}")
        print(f"Email: {request.email}")
        print(f"UID: {request.uid}")
        
        # Check cooldown: prevent spamming resend button (30-second window)
        COOLDOWN_SECONDS = 30
        otp_doc: Any = db.collection("otps").document(request.email).get()
        
        if otp_doc.exists:
            existing_data = otp_doc.to_dict()
            created_at = existing_data.get("createdAt")
            
            if created_at:
                time_elapsed = (datetime.now(timezone.utc) - created_at).total_seconds()
                
                if time_elapsed < COOLDOWN_SECONDS:
                    time_remaining = int(COOLDOWN_SECONDS - time_elapsed)
                    print(f"⏱️  Cooldown active: {time_remaining}s remaining")
                    raise HTTPException(
                        status_code=429,
                        detail=f"Please wait {time_remaining} seconds before requesting a new OTP"
                    )
        
        # Generate a cryptographically secure random 6-digit OTP
        otp_code = str(secrets.randbelow(1000000)).zfill(6)
        print(f"Generated OTP: {otp_code}")
        
        # Save to Firestore with a 10-minute expiry
        expiry_time = datetime.now(timezone.utc) + timedelta(minutes=10)
        
        db.collection("otps").document(request.email).set({
            "otp": otp_code,
            "uid": request.uid,
            "expiresAt": expiry_time,
            "createdAt": datetime.now(timezone.utc),
            "method": "email"
        })
        print(f"✓ OTP saved to Firestore")
        
        # Send email via Resend
        print(f"📧 Sending email via Resend...")
        try:
            _send_otp_email(request.email, otp_code, request.uid)
        except Exception as email_error:
            # If email send fails, delete the OTP so user can retry
            db.collection("otps").document(request.email).delete()
            print(f"❌ Email send failed, OTP deleted from Firestore")
            raise HTTPException(
                status_code=502,
                detail=f"Failed to send OTP email: {str(email_error)}"
            )
        
        print(f"{'='*70}\n")
        
        return {
            "message": "OTP sent successfully",
            "email": request.email,
            "expiresIn": 600  # 10 minutes in seconds
        }
        
    except HTTPException as he:
        raise he
    except Exception as e:
        import traceback
        print(f"\n{'='*70}")
        print(f"❌ ERROR IN SEND EMAIL OTP")
        print(f"{'='*70}")
        print(traceback.format_exc())
        print(f"{'='*70}\n")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/verify-email-otp")
async def verify_email_otp(request: VerifyEmailOTPRequest):
    try:
        from backend.database import db
        doc_ref = db.collection("otps").document(request.email)
        doc: Any = doc_ref.get()
        
        if not doc.exists:
            raise HTTPException(status_code=400, detail="No active OTP found for this email. Please request a new one.")
            
        data = doc.to_dict()
        
        # Check expiry
        expires_at = data.get("expiresAt")
        if expires_at and datetime.now(timezone.utc) > expires_at:
            doc_ref.delete()
            raise HTTPException(status_code=400, detail="OTP has expired. Please request a new one.")
            
        # Check matching code
        if data.get("otp") != request.otp:
            raise HTTPException(status_code=400, detail="Invalid OTP code.")
            
        # Success! Delete the OTP so it can't be reused
        doc_ref.delete()
        
        return {"message": "OTP verified successfully", "uid": data.get("uid")}
    except HTTPException as he:
        raise he
    except Exception as e:
        import traceback
        traceback.print_exc()
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
        
        from backend.database import db
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
        from backend.database import db
        docs = db.collection("admins").get()
        members = []
        for doc in docs:
            data = doc.to_dict()
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
        from backend.database import db
        # Delete from Firebase Auth
        try:
            auth.delete_user(uid)
        except Exception as auth_e:
            print(f"Auth delete error for {uid}: {auth_e}")
            
        # Delete document from Firestore
        db.collection("admins").document(uid).delete()
        return {"message": "Team member deleted successfully", "uid": uid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/signup/musician")
async def signup_musician(request: MusicianSignUpRequest):
    try:
        from datetime import datetime
        try:
            existing_user = auth.get_user_by_email(request.email)
            user = auth.update_user(existing_user.uid, display_name=request.fullName)
        except auth.UserNotFoundError:
            user = auth.create_user(
                email=request.email,
                password=request.password,
                display_name=request.fullName
            )
        
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
            "createdAt": SERVER_TIMESTAMP
        }
        db.collection("musicians").document(user.uid).set(user_data)
        
        from backend.services.admin_notification_service import AdminNotificationService
        AdminNotificationService.user_activity("New musician registered", f"{request.fullName} ({request.email}) joined as a musician.")
        AdminNotificationService.check_milestones()
        
        return {"message": "Musician created successfully", "uid": user.uid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/signup")
async def signup(request: SignUpRequest):
    try:
        from datetime import datetime
        try:
            existing_user = auth.get_user_by_email(request.email)
            user = auth.update_user(existing_user.uid, display_name=request.name)
        except auth.UserNotFoundError:
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
            "createdAt": SERVER_TIMESTAMP
        }
        db.collection("organizers").document(user.uid).set(user_data)
        
        from backend.services.admin_notification_service import AdminNotificationService
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
        
        is_2fa_enabled = profile.get("is2FAEnabled") if profile else False
        phone_number = profile.get("phoneNumber") if profile else None
        two_factor_method = profile.get("twoFactorMethod") if profile else None
        
        # Convert method names for frontend compatibility
        two_factor_method_frontend = None
        if two_factor_method == "email":
            two_factor_method_frontend = "email_link"
        elif two_factor_method == "sms":
            two_factor_method_frontend = "sms"
        
        return {
            "idToken": data["idToken"],
            "email": data["email"],
            "localId": uid,
            "role": role,
            "displayName": display_name,
            "profileImageUrl": profile_image,
            "is2FAEnabled": is_2fa_enabled,
            "phoneNumber": phone_number,
            "twoFactorMethod": two_factor_method_frontend
        }
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        SecurityService.create_log("Failed login attempt", request.email, status="failed")
        raise HTTPException(status_code=500, detail=str(e))


class SendVerificationRequest(BaseModel):
    email: str
    id_token: str


class CheckVerificationRequest(BaseModel):
    uid: str


class CreateUserRequest(BaseModel):
    email: str
    password: str


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
            raise HTTPException(status_code=400, detail=data["error"]["message"])
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
    """
    Enable or disable 2FA for a user.
    
    Args:
        uid: User ID
        enabled: True to enable, False to disable
        userType: 'musician', 'organizer', or 'admin'
    """
    try:
        from backend.database import db
        
        # Map userType to collection name
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
        
        print(f"\n{'='*60}")
        print(f"✓ 2FA {'ENABLED' if request.enabled else 'DISABLED'}")
        print(f"{'='*60}")
        print(f"UID: {request.uid}")
        print(f"Type: {request.userType}")
        print(f"Collection: {collection}")
        print(f"{'='*60}\n")
        
        return {
            "message": f"2FA {'enabled' if request.enabled else 'disabled'} successfully",
            "is2FAEnabled": request.enabled
        }
    except Exception as e:
        print(f"\n{'='*60}")
        print(f"❌ ERROR IN ENABLE 2FA")
        print(f"{'='*60}")
        print(str(e))
        print(f"{'='*60}\n")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/2fa/set-method")
async def set_2fa_method(request: Set2FAMethodRequest):
    """
    Set the 2FA method (SMS or Email) for a user.
    
    Args:
        uid: User ID
        method: 'sms' or 'email'
        userType: 'musician', 'organizer', or 'admin'
    """
    try:
        from backend.database import db
        
        if request.method not in ['sms', 'email']:
            raise HTTPException(status_code=400, detail="Method must be 'sms' or 'email'")
        
        # Map userType to collection name
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
        
        print(f"\n{'='*60}")
        print(f"✓ 2FA METHOD UPDATED")
        print(f"{'='*60}")
        print(f"UID: {request.uid}")
        print(f"Method: {request.method.upper()}")
        print(f"Type: {request.userType}")
        print(f"Collection: {collection}")
        print(f"{'='*60}\n")
        
        return {
            "message": f"2FA method set to {request.method}",
            "twoFactorMethod": request.method
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"\n{'='*60}")
        print(f"❌ ERROR IN SET 2FA METHOD")
        print(f"{'='*60}")
        print(str(e))
        print(f"{'='*60}\n")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/2fa/save-phone")
async def save_phone_number(request: SavePhoneNumberRequest):
    """
    Save phone number for SMS 2FA.
    
    Args:
        uid: User ID
        phoneNumber: Phone number in format +1234567890
        userType: 'musician', 'organizer', or 'admin'
    """
    try:
        from backend.database import db
        
        if not request.phoneNumber or len(request.phoneNumber) < 10:
            raise HTTPException(status_code=400, detail="Invalid phone number format")
        
        # Map userType to collection name
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
        
        print(f"\n{'='*60}")
        print(f"✓ PHONE NUMBER SAVED")
        print(f"{'='*60}")
        print(f"UID: {request.uid}")
        print(f"Phone: {request.phoneNumber}")
        print(f"Type: {request.userType}")
        print(f"Collection: {collection}")
        print(f"{'='*60}\n")
        
        return {
            "message": "Phone number saved successfully",
            "phoneNumber": request.phoneNumber
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"\n{'='*60}")
        print(f"❌ ERROR IN SAVE PHONE NUMBER")
        print(f"{'='*60}")
        print(str(e))
        print(f"{'='*60}\n")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/send-email-link-2fa")
async def send_email_link_2fa(request: SendEmailLink2FARequest):
    """Send 2FA email link using Firebase Auth Identity Toolkit API."""
    try:
        continue_url = request.continueUrl if request.continueUrl else "http://localhost:3000/verify-2fa-link"
        data = _firebase_auth_request("accounts:sendOobCode", {
            "requestType": "EMAIL_SIGNIN",
            "email": request.email,
            "continueUrl": continue_url,
            "canHandleCodeInApp": True,
        })
        if "error" in data:
            print(f"Firebase OOB Error: {data['error']}")
            raise HTTPException(status_code=400, detail=data["error"].get("message", "Failed to send email link"))
        print(f"\n{'='*60}")
        print(f"📧 2FA EMAIL VERIFICATION LINK SENT VIA FIREBASE AUTH")
        print(f"{'='*60}")
        print(f"To: {request.email}")
        print(f"Continue URL: {continue_url}")
        print(f"{'='*60}\n")
        return {"message": "Email verification link sent successfully", "email": request.email}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

