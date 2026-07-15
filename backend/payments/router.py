import os
from backend.database import db
import stripe


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
    WalletDataResponse,
    TransactionResponse,
    EphemeralKeyRequest,
    EphemeralKeyResponse,
    SetupIntentRequest,
    SetupIntentResponse,
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

@router.get("/organizer/{organizer_id}/wallet", response_model=WalletDataResponse)
async def get_wallet_data(organizer_id: str):
    try:
        data = StripeManager.get_organizer_wallet_data(organizer_id)
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/organizer/{organizer_id}/transactions", response_model=TransactionResponse)
async def get_transactions(organizer_id: str):
    try:
        transactions = StripeManager.get_organizer_transactions(organizer_id)
        return {"transactions": transactions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/organizer/ephemeral-key", response_model=EphemeralKeyResponse)
async def create_ephemeral_key(request: EphemeralKeyRequest, x_stripe_version: str = Header("2024-06-20")):
    try:
        key = StripeManager.create_ephemeral_key(request.organizerId, x_stripe_version)
        return {"secret": key.secret}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/organizer/setup-intent", response_model=SetupIntentResponse)
async def create_setup_intent(request: SetupIntentRequest):
    try:
        setup_intent = StripeManager.create_setup_intent(request.organizerId)
        return {
            "clientSecret": setup_intent.client_secret,
            "customerId": setup_intent.customer
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/organizer/add-funds")
async def add_funds_to_wallet(request: dict):
    try:
        organizer_id = request.get("organizerId")
        payment_method_id = request.get("paymentMethodId")
        amount = float(request.get("amount", 0))
        
        if not organizer_id or not payment_method_id or amount <= 0:
            raise ValueError("organizerId, paymentMethodId, and amount (> 0) are required")
        
        result = StripeManager.add_funds_to_wallet(organizer_id, payment_method_id, amount)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/organizer/save-payment-method")
async def save_payment_method(request: dict):
    try:
        organizer_id = request.get("organizerId")
        payment_method_id = request.get("paymentMethodId")
        
        if not organizer_id or not payment_method_id:
            raise ValueError("organizerId and paymentMethodId are required")
        
        payment_method_data = StripeManager.save_payment_method_to_db(organizer_id, payment_method_id)
        return {"success": True, "paymentMethod": payment_method_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/booking/{booking_id}/deposit", response_model=BookingDepositResponse)
async def deposit_to_escrow(booking_id: str, request: BookingDepositRequest):
    try:
        result = StripeManager.deposit_to_escrow(
            booking_id=booking_id,
            organizer_id=request.organizerId,
            amount=request.amount,
            currency=request.currency or "usd"
        )
        return {
            "paymentIntentId": "",
            "chargeId": None,
            "status": result["escrow_status"]
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


@router.post("/organizer/payment-intent")
async def create_payment_intent(request: dict):
    try:
        organizer_id = request.get("organizerId")
        amount = float(request.get("amount", 0))
        if not organizer_id or amount <= 0:
            raise ValueError("organizerId and amount (> 0) are required")
        result = StripeManager.create_payment_intent_for_sheet(organizer_id, amount)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/musician/onboard/link")
async def musician_onboard_link(request: dict):
    try:
        musician_id = request.get("musicianId")
        refresh_url = request.get("refreshUrl", "https://onlygigz.com/refresh")
        return_url = request.get("returnUrl", "https://onlygigz.com/return")
        if not musician_id:
            raise ValueError("musicianId is required")
        url = StripeManager.create_musician_onboarding_link_by_id(musician_id, refresh_url, return_url)
        return {"onboardingUrl": url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/musician/payout")
async def musician_payout(request: dict):
    try:
        musician_id = request.get("musicianId")
        amount = float(request.get("amount", 0))
        if not musician_id or amount <= 0:
            raise ValueError("musicianId and amount (> 0) are required")
        result = StripeManager.musician_payout(musician_id, amount)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/musician/{musician_id}/balance")
async def get_musician_balance(musician_id: str):
    try:
        StripeManager._assert_api_key()
        musician_ref = db.collection("musicians").document(musician_id)
        musician_doc = musician_ref.get()
        if not musician_doc.exists:
            raise ValueError(f"Musician {musician_id} not found")
        
        musician = musician_doc.to_dict()
        connected_account_id = musician.get("stripe_id")
        
        balance = 0.0
        if connected_account_id:
            try:
                stripe_balance = stripe.Balance.retrieve(stripe_account=connected_account_id)
                balance = stripe_balance.available[0].amount / 100.0 if stripe_balance.available else 0.0
            except Exception:
                pass
        
        return {"balance": balance, "stripeAccountId": connected_account_id or ""}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/musician/{musician_id}/connected-account")
async def get_musician_connected_account(musician_id: str):
    try:
        StripeManager._assert_api_key()
        musician_ref = db.collection("musicians").document(musician_id)
        musician_doc = musician_ref.get()
        if not musician_doc.exists:
            return {"connected_account_id": "", "bank_accounts": [], "status": "not_connected"}
        
        musician = musician_doc.to_dict()
        connect_id = musician.get("stripe_connect_id", "")
        status = musician.get("stripe_status", "not_connected")
        
        if not connect_id or not connect_id.startswith("acct_"):
            return {"connected_account_id": "", "bank_accounts": [], "status": "not_connected"}
        
        # Fetch external accounts (bank accounts) from the connected account
        bank_accounts = []
        try:
            ext_accounts = stripe.Account.list_external_accounts(connect_id, object="bank_account")
            for ea in ext_accounts.data:
                bank_accounts.append({
                    "id": ea.id,
                    "bank_name": getattr(ea, 'bank_name', 'Bank'),
                    "last4": getattr(ea, 'last4', '????'),
                    "country": getattr(ea, 'country', ''),
                    "currency": getattr(ea, 'currency', 'usd'),
                })
        except Exception as e:
            print(f"Error fetching bank accounts: {e}")
        
        return {
            "connected_account_id": connect_id,
            "bank_accounts": bank_accounts,
            "status": status,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/webhook")
async def stripe_webhook(request: Request, stripe_signature: str = Header(None)):
    try:
        payload = await request.body()
        print(f"Webhook received - signature: {stripe_signature[:20] if stripe_signature else 'None'}...")
        event = StripeManager.construct_event(payload.decode("utf-8"), stripe_signature)
        print(f"Webhook event type: {event.get('type', 'unknown')}")
        StripeWebhookHandler.handle_event(event)
        return {"received": True}
    except ValueError as e:
        print(f"Webhook signature error: {e}")
        raise HTTPException(status_code=400, detail=f"Signature error: {e}")
    except Exception as e:
        print(f"Webhook error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
