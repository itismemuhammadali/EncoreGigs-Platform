from pydantic import BaseModel, EmailStr
from typing import List, Optional

class MusicianSignUpRequest(BaseModel):
    email: EmailStr
    password: str
    fullName: str
    bio: str
    genres: List[str]
    instruments: List[str]
    feeRange: int
    yearsOfExperience: int
    location: str
    website: Optional[str] = None
    portfolio: Optional[dict] = None
    profileImageUrl: Optional[str] = None

class PortfolioItem(BaseModel):
    url: str
    type: str  # 'image', 'video', 'music'
    title: Optional[str] = ""
    description: Optional[str] = ""
    externalUrl: Optional[str] = ""

class PortfolioUpdateRequest(BaseModel):
    uid: str
    item: PortfolioItem
    action: str  # 'add', 'update', 'delete'
    oldUrl: Optional[str] = None
