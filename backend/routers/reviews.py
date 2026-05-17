from fastapi import APIRouter, HTTPException, Body
from backend.services.review_service import ReviewService
from backend.models.review_models import ReviewFlagRequest
from typing import List, Dict

router = APIRouter(prefix="/reviews", tags=["reviews"])

@router.get("/list")
async def list_reviews():
    try:
        reviews = ReviewService.get_all_reviews()
        return reviews
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/stats")
async def get_review_stats():
    try:
        stats = ReviewService.get_review_stats()
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{review_id}/flag")
async def toggle_flag(review_id: str, request: ReviewFlagRequest):
    try:
        success = ReviewService.toggle_flag(review_id, request.isFlagged)
        if not success:
            raise HTTPException(status_code=404, detail="Review not found")
        return {"message": f"Review {'flagged' if request.isFlagged else 'unflagged'} successfully"}
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{review_id}")
async def delete_review(review_id: str):
    try:
        success = ReviewService.delete_review(review_id)
        if not success:
            raise HTTPException(status_code=404, detail="Review not found")
        return {"message": "Review deleted successfully"}
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))
