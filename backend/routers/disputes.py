from fastapi import APIRouter, HTTPException, Query
from backend.services.dispute_service import DisputeService
from backend.models.gig_models import DisputeRequest
from typing import Optional, List

router = APIRouter(prefix="/disputes", tags=["disputes"])

@router.post("/create")
async def create_dispute(request: DisputeRequest):
    try:
        dispute_id = DisputeService.create_dispute(request)
        return {"message": "Dispute created successfully", "disputeId": dispute_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/list")
async def list_disputes(user_id: Optional[str] = Query(None)):
    try:
        disputes = DisputeService.get_disputes(user_id)
        return disputes
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{dispute_id}")
async def get_dispute(dispute_id: str):
    try:
        dispute = DisputeService.get_dispute_by_id(dispute_id)
        if not dispute:
            raise HTTPException(status_code=404, detail="Dispute not found")
        return dispute
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{dispute_id}/resolve")
async def resolve_dispute(dispute_id: str):
    try:
        DisputeService.resolve_dispute(dispute_id)
        return {"message": "Dispute resolved successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
