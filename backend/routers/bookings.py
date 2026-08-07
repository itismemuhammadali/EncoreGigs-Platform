from fastapi import APIRouter, HTTPException, Query, Response
from backend.services.booking_service import BookingService
from backend.models.gig_models import BookingConfirmRequest
from typing import Optional

router = APIRouter(prefix="/bookings", tags=["bookings"])

@router.get("/{booking_id}/download-contract")
@router.get("/{booking_id}/contract/pdf")
async def download_contract(booking_id: str):
    try:
        pdf_content = BookingService.generate_contract_pdf(booking_id)
        if not pdf_content:
            raise HTTPException(status_code=404, detail="Contract not found")
        
        return Response(
            content=pdf_content,
            media_type="application/pdf",
            headers={
                "Content-Disposition": f"attachment; filename=OnlyGigz_Contract_{booking_id}.pdf"
            }
        )
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/confirm")
async def confirm_booking(request: BookingConfirmRequest):
    try:
        booking_id = BookingService.confirm_booking(request)
        return {"message": "Booking confirmed successfully", "bookingId": booking_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/list")
async def list_bookings(
    musician_id: Optional[str] = Query(None),
    organizer_id: Optional[str] = Query(None)
):
    try:
        bookings = BookingService.get_bookings(musician_id, organizer_id)
        return bookings
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{booking_id}")
async def get_booking(booking_id: str):
    try:
        booking = BookingService.get_booking_by_id(booking_id)
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found")
        return booking
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))

from pydantic import BaseModel
class MusicianSignRequest(BaseModel):
    signatureUrl: str

@router.post("/{booking_id}/musician-sign")
async def musician_sign(booking_id: str, request: MusicianSignRequest):
    try:
        result = BookingService.musician_sign_contract(booking_id, request.signatureUrl)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
