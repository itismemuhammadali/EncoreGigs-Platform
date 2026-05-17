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
    bio: Optional[str] = None
    profileImageUrl: Optional[str] = None
    instruments: Optional[List[str]] = None
    genres: Optional[List[str]] = None
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

class PasswordUpdateRequest(BaseModel):
    uid: str
    newPassword: str

class UserStatusRequest(BaseModel):
    uid: str
    status: str # 'active', 'suspended'
    email: str
