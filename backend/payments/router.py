import os

from fastapi import APIRouter, HTTPException, Request, Header
from backend.payments.models import (
    MusicianOnboardRequest,
    MusicianOnboardResponse,
    OrganizerCustomerRequest,
    OrganizerCustomerResponse,
    BookingDepositRequest,
    BookingDepositResponse,
    BookingReleaseResponse,
    BookingRefundResponse,
)
from backend.payments.service import StripeManager
from backend.payments.webhooks import StripeWebhookHandler

router = APIRouter(prefix="/payments", tags=["payments"])

@router.post("/musician/onboard", response_model=MusicianOnboardResponse)
async def musician_onboard(request: MusicianOnboardRequest):
    try:
        account_id = StripeManager.create_musician_account(request.musicianId)
        onboarding_url = StripeManager.create_musician_onboarding_link(
            account_id,
            request.refreshUrl,
            request.returnUrl
        )
        return {
            "stripeAccountId": account_id,
            "onboardingUrl": onboarding_url,
            "stripeStatus": "pending"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/organizer/customer", response_model=OrganizerCustomerResponse)
async def create_organizer_customer(request: OrganizerCustomerRequest):
    try:
        customer_id = StripeManager.create_organizer_customer(request.organizerId)
        return {"stripeCustomerId": customer_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/booking/{booking_id}/deposit", response_model=BookingDepositResponse)
async def deposit_to_escrow(booking_id: str, request: BookingDepositRequest):
    try:
        payment_intent = StripeManager.deposit_to_escrow(
            booking_id=booking_id,
            organizer_id=request.organizerId,
            amount=request.amount,
            payment_method_id=request.paymentMethodId,
            currency=request.currency or "usd"
        )
        charge_id = None
        if payment_intent.charges.data:
            charge_id = payment_intent.charges.data[0].id
        return {
            "paymentIntentId": payment_intent.id,
            "chargeId": charge_id,
            "status": payment_intent.status
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/booking/{booking_id}/release", response_model=BookingReleaseResponse)
async def release_booking_payment(booking_id: str):
    try:
        release_result = StripeManager.release_booking_payment(booking_id)
        transfer = release_result["transfer"]
        return {
            "transferId": transfer.id,
            "currency": release_result["currency"],
            "grossAmount": release_result["gross_amount"],
            "feeAmount": release_result["fee_amount"],
            "netAmount": release_result["net_amount"]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/booking/{booking_id}/refund", response_model=BookingRefundResponse)
async def refund_booking_payment(booking_id: str):
    try:
        refund = StripeManager.refund_booking_payment(booking_id)
        return {"refundId": refund.id, "status": refund.status}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/webhook")
async def stripe_webhook(request: Request, stripe_signature: str = Header(None)):
    try:
        payload = await request.body()
        event = StripeManager.construct_event(payload.decode("utf-8"), stripe_signature)
        StripeWebhookHandler.handle_event(event)
        return {"received": True}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
