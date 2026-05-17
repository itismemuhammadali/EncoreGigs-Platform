from fastapi import APIRouter, HTTPException, Query
from backend.services.gig_service import GigService
from backend.models.gig_models import GigRequest, ApplicationRequest
from typing import Optional, List

router = APIRouter(prefix="/gigs", tags=["gigs"])

@router.post("/create")
async def create_gig(request: GigRequest):
    try:
        gig_id = GigService.create_gig(request)
        return {"message": "Gig created successfully", "gigId": gig_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/list")
async def list_gigs(
    status: Optional[str] = Query(None),
    organizer_id: Optional[str] = Query(None),
    search_query: Optional[str] = Query(None)
):
    try:
        gigs = GigService.get_gigs(status, organizer_id, search_query)
        return gigs
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{gig_id}")
async def get_gig(gig_id: str):
    try:
        gig = GigService.get_gig_by_id(gig_id)
        if not gig:
            raise HTTPException(status_code=404, detail="Gig not found")
        return gig
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/apply")
async def apply_to_gig(request: ApplicationRequest):
    try:
        application_id = GigService.apply_to_gig(request)
        return {"message": "Application submitted successfully", "applicationId": application_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/applications/list")
async def list_applications(
    gig_id: Optional[str] = Query(None),
    musician_id: Optional[str] = Query(None),
    organizer_id: Optional[str] = Query(None),
    status: Optional[str] = Query(None)
):
    try:
        applications = GigService.get_applications(gig_id, musician_id, organizer_id, status)
        return applications
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/applications/{application_id}/status")
async def update_application_status(application_id: str, status: str = Query(...)):
    try:
        success = GigService.update_application_status(application_id, status)
        if not success:
            raise HTTPException(status_code=404, detail="Application not found")
        return {"message": "Application status updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/reviews/{musician_id}")
async def list_reviews(musician_id: str, limit: int = 5):
    try:
        reviews = GigService.get_reviews(musician_id, limit)
        return reviews
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/dashboard/stats/{organizer_id}")
async def get_dashboard_stats(organizer_id: str):
    try:
        stats = GigService.get_dashboard_stats(organizer_id)
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/dashboard/activity/{user_id}")
async def get_recent_activity(user_id: str, limit: int = Query(10)):
    try:
        from backend.services.auth_service import AuthService
        profile = AuthService.get_profile(user_id)
        if not profile:
            raise HTTPException(status_code=404, detail="User not found")
        
        role = profile.get("role")
        if role == "organizer":
            activity = GigService.get_recent_activity(user_id, limit)
        else:
            activity = GigService.get_musician_activity(user_id, limit)
        return activity
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))
