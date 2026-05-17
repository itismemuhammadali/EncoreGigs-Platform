from pydantic import BaseModel
from typing import List, Optional

class GigRequest(BaseModel):
    title: str
    description: str
    requirements: List[str]
    genres: List[str]
    date: str
    time: str
    budget: str
    location: str
    organizerId: str
    imageUrl: Optional[str] = None
    duration: Optional[str] = None

class ApplicationRequest(BaseModel):
    gigId: str
    gigTitle: str
    musicianId: str
    organizerId: str
    organizerName: Optional[str] = "Event Organizer"
    gigDate: Optional[str] = None
    gigTime: Optional[str] = None
    duration: Optional[str] = None
    proposedRate: Optional[str] = None
    coverMessage: Optional[str] = None
    attachments: Optional[List[str]] = []
    status: str = "pending"

class BookingConfirmRequest(BaseModel):
    gigId: str
    gigTitle: str
    musicianId: str
    musicianName: str
    organizerId: str
    organizerName: str
    location: str
    amount: float
    signatureUrl: str
    gigDate: Optional[str] = None
    gigTime: str
    duration: Optional[str] = None
    status: str = "confirmed"
    createdAt: Optional[str] = None
    sections: Optional[dict] = None
