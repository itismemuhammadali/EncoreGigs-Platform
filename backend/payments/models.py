from pydantic import BaseModel
from typing import Optional

class MusicianOnboardRequest(BaseModel):
    musicianId: str
    refreshUrl: str
    returnUrl: str

class MusicianOnboardResponse(BaseModel):
    stripeAccountId: str
    onboardingUrl: str
    stripeStatus: str

class OrganizerCustomerRequest(BaseModel):
    organizerId: str

class OrganizerCustomerResponse(BaseModel):
    stripeCustomerId: str

class BookingDepositRequest(BaseModel):
    organizerId: str
    amount: float
    paymentMethodId: str
    currency: Optional[str] = "usd"

class BookingDepositResponse(BaseModel):
    paymentIntentId: str
    chargeId: Optional[str]
    status: str

class BookingReleaseResponse(BaseModel):
    transferId: str
    currency: str
    grossAmount: float
    feeAmount: float
    netAmount: float

class BookingRefundResponse(BaseModel):
    refundId: str
    status: str
