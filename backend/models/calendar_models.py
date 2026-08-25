from pydantic import BaseModel
from typing import Optional

class CalendarEventBase(BaseModel):
    userId: str
    userType: str  # 'organizer' | 'musician'
    source: str    # 'onlygigz_gig' | 'onlygigz_booking' | 'outside_gig' | 'availability_block' | 'unavailable_block' | 'hold'
    gigId: Optional[str] = None
    bookingId: Optional[str] = None
    title: str
    startTime: str
    endTime: str
    isAllDay: bool = False
    status: str    # 'OPEN_DATE' | 'POSTED' | 'REVIEWING' | 'BOOKED' | 'CONFIRMED' | 'COMPLETED' | 'CANCELLED' | 'AVAILABLE' | 'UNAVAILABLE' | 'HOLD' | 'OUTSIDE_GIG'
    privacyLevel: str = 'private'
    location: Optional[str] = None
    rate: Optional[str] = None
    notes: Optional[str] = None

class CalendarEventCreate(CalendarEventBase):
    pass

class CalendarEventResponse(CalendarEventBase):
    id: str
