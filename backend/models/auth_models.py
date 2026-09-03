from pydantic import BaseModel, EmailStr
from typing import Optional, List

class SignUpRequest(BaseModel):
    email: EmailStr
    password: str
    name: str
    orgName: str
    type: str
    contact: str
    location: str
    bio: str

class AdminSignUpRequest(BaseModel):
    email: EmailStr
    password: str
    firstName: str
    lastName: str

class ProfileUpdateRequest(BaseModel):
    uid: str
    firstName: Optional[str] = None
    lastName: Optional[str] = None
    name: Optional[str] = None
    email: str
    contact: Optional[str] = None
    location: Optional[str] = None
    primaryCity: Optional[str] = None
    primaryState: Optional[str] = None
    primaryZip: Optional[str] = None
    secondaryCity: Optional[str] = None
    secondaryState: Optional[str] = None
    secondaryZip: Optional[str] = None
    travelRadius: Optional[int] = None
    bio: Optional[str] = None
    profileImageUrl: Optional[str] = None
    bannerImageUrl: Optional[str] = None
    instruments: Optional[List[str]] = None
    genres: Optional[List[str]] = None
    tags: Optional[List[str]] = None
    feeRange: Optional[float] = None
    maxFeeRange: Optional[float] = None
    yearsOfExperience: Optional[int] = None
    orgName: Optional[str] = None
    type: Optional[str] = None

class OrganizationUpdateRequest(BaseModel):
    uid: str
    orgName: str
    type: str
    businessEmail: str
    businessPhone: str
    address: str
    city: str
    state: str
    zipCode: str
    website: str
    taxId: str
    description: str
    licenseUrl: Optional[str] = None

class SignInRequest(BaseModel):
    email: EmailStr
    password: str

class ForgotPasswordRequest(BaseModel):
    email: EmailStr
    role: Optional[str] = None

class PasswordUpdateRequest(BaseModel):
    uid: str
    newPassword: str

class UserStatusRequest(BaseModel):
    uid: str
    status: str # 'active', 'suspended'
    email: str

class SendEmailOTPRequest(BaseModel):
    email: EmailStr
    uid: str

class VerifyEmailOTPRequest(BaseModel):
    email: EmailStr
    otp: str

class Enable2FARequest(BaseModel):
    uid: str
    enabled: bool
    userType: str  # 'musician' or 'organizer'

class Set2FAMethodRequest(BaseModel):
    uid: str
    method: str  # 'sms' or 'email'
    userType: str  # 'musician' or 'organizer'

class SavePhoneNumberRequest(BaseModel):
    uid: str
    phoneNumber: str
    userType: str  # 'musician' or 'organizer'

class SendEmailLink2FARequest(BaseModel):
    uid: str
    email: EmailStr
    userType: str  # 'musician', 'organizer', or 'admin'
    idToken: Optional[str] = None  # Optional, frontend sends it but we don't need it
    continueUrl: Optional[str] = None

class CreateAdminMemberRequest(BaseModel):
    firstName: str
    lastName: str
    email: EmailStr
    password: str
    role: str  # 'super_admin', 'admin', or 'support'

class SendApprovalEmailRequest(BaseModel):
    email: EmailStr
    name: Optional[str] = "User"

