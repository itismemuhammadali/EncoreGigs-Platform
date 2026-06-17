from fastapi import APIRouter, HTTPException, Query
from backend.services.scraper_service import ScraperService
from typing import Optional, List, Dict, Any

router = APIRouter(prefix="/scraper", tags=["scraper"])

@router.get("/stats")
async def get_scraper_stats():
    try:
        stats = ScraperService.get_stats()
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/runs")
async def get_recent_runs(limit: int = Query(5)):
    try:
        runs = ScraperService.get_recent_runs(limit)
        return runs
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/imported")
async def get_imported_gigs(
    limit: int = Query(10),
    filter_type: str = Query("all")
):
    try:
        gigs = ScraperService.get_imported_gigs(limit, filter_type)
        return gigs
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/run")
async def run_scraper():
    try:
        success = ScraperService.run_scraper()
        if not success:
            raise HTTPException(status_code=500, detail="Failed to trigger scraper")
        return {"message": "Scraper triggered successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/gigs/{gig_id}")
async def delete_scraped_gig(gig_id: str):
    try:
        success = ScraperService.delete_gig(gig_id)
        if not success:
            raise HTTPException(status_code=404, detail="Gig not found")
        return {"message": "Gig deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/gigs/{gig_id}")
async def update_scraped_gig(gig_id: str, updates: Dict[str, Any]):
    try:
        success = ScraperService.update_gig(gig_id, updates)
        if not success:
            raise HTTPException(status_code=404, detail="Gig not found")
        return {"message": "Gig updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
