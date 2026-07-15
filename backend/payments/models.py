from pydantic import BaseModel
from typing import Optional, List, Any

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
    paymentMethodId: Optional[str] = None
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

class WalletDataResponse(BaseModel):
    payment_methods: List[Any]
    stripe_customer_id: str
    wallet_balance: float

class TransactionResponse(BaseModel):
    transactions: List[Any]

class EphemeralKeyRequest(BaseModel):
    organizerId: str

class EphemeralKeyResponse(BaseModel):
    secret: str

class SetupIntentRequest(BaseModel):
    organizerId: str

class SetupIntentResponse(BaseModel):
    clientSecret: str
    customerId: str
