from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from backend.services.featured_service import FeaturedService

router = APIRouter(prefix="/featured", tags=["featured"])

class FeaturedPurchaseRequest(BaseModel):
    musicianId: str
    plan: str
    amount: float
    paymentToken: Optional[str] = None

@router.post("/purchase")
async def purchase_featured(request: FeaturedPurchaseRequest):
    try:
        result = FeaturedService.purchase_featured(
            musician_id=request.musicianId,
            plan=request.plan,
            amount=request.amount,
            payment_token=request.paymentToken
        )
        return result
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/artists")
async def get_featured_artists():
    try:
        artists = FeaturedService.get_featured_artists()
        return artists
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{artist_id}/revoke")
async def revoke_featured(artist_id: str):
    try:
        success = FeaturedService.revoke_featured(artist_id)
        if not success:
            raise HTTPException(status_code=404, detail="Featured artist record not found")
        return {"message": f"Featured placement for {artist_id} revoked successfully."}
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
