from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime

class OrganizerDetails(BaseModel):
    # Personal Information
    name: str
    personal_email: Optional[str] = None
    personal_phone: Optional[str] = None
    bio: Optional[str] = None
    location: Optional[str] = None
    profile_image_url: Optional[str] = None

    # Organization Details
    organization_name: Optional[str] = None
    organization_type: Optional[str] = None # 'Venue / Club', 'Event Planner', etc.
    business_email: Optional[str] = None
    business_phone: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    zip_code: Optional[str] = None
    website: Optional[str] = None
    tax_id: Optional[str] = None
    description: Optional[str] = None
    license_url: Optional[str] = None
    
    social_links: Dict[str, str] = Field(default_factory=dict)

class GigDetails(BaseModel):
    # Post Gig Screen Fields
    title: str
    description: str
    requirements: List[str] = Field(default_factory=list)
    genres: List[str] = Field(default_factory=list)
    date: Optional[str] = None # MM/DD/YYYY
    time: Optional[str] = None # e.g., 8:00 PM
    budget: Optional[str] = None # e.g., $500-800
    duration: Optional[str] = None # e.g., 2 hours
    location: str # e.g., Blue Note Jazz Club, NYC
    image_url: Optional[str] = None
    
    # Metadata
    source_url: str
    source_type: str # e.g., "facebook", "craigslist"
    external_id: str
    scraped_at: datetime = Field(default_factory=datetime.now)
    
    organizer: OrganizerDetails
