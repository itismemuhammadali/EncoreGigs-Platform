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
    bannerImageUrl: Optional[str] = None
    primaryGenre: Optional[str] = ""
    subgenres: Optional[List[str]] = []
    tags: Optional[List[str]] = []
    hourlyRate: Optional[int] = 50
    primaryCity: Optional[str] = ""
    primaryState: Optional[str] = ""
    primaryZip: Optional[str] = ""
    secondaryCity: Optional[str] = ""
    secondaryState: Optional[str] = ""
    secondaryZip: Optional[str] = ""
    travelRadius: Optional[int] = 50

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
