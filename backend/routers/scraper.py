from fastapi import APIRouter, HTTPException, Query
from backend.services.scraper_service import ScraperService
from pydantic import BaseModel
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

@router.post("/gigs/{gig_id}/publish")
async def publish_gig_to_app(gig_id: str):
    try:
        result = ScraperService.publish_gig(gig_id)
        if result is None:
            raise HTTPException(status_code=404, detail="Gig not found")
        return {"message": "Gig published to app", "gigId": result}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/publish-all")
async def publish_all_to_app():
    try:
        result = ScraperService.publish_all_unpublished()
        published = result.get("published", 0)
        already = result.get("alreadyPublished", 0)
        if published > 0:
            return {"message": f"Published {published} new gigs to app", "publishedCount": published, **result}
        else:
            return {"message": f"All {already} gigs are already published in app", "publishedCount": 0, **result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/sources")
async def get_scraper_sources():
    try:
        return ScraperService.get_sources()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class AddSourceRequest(BaseModel):
    url: str
    name: Optional[str] = "Facebook Group"
    type: Optional[str] = "facebook_group"

@router.post("/sources")
async def add_scraper_source(request: AddSourceRequest):
    try:
        result = ScraperService.add_source(request.url, request.name, request.type)
        if not result:
            raise HTTPException(status_code=500, detail="Failed to add scraper source")
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/sources/{source_id}")
async def delete_scraper_source(source_id: str):
    try:
        success = ScraperService.delete_source(source_id)
        if not success:
            raise HTTPException(status_code=404, detail="Source not found")
        return {"message": "Source deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class UpdateCookiesRequest(BaseModel):
    cookies: str

@router.post("/cookies")
async def update_scraper_cookies(request: UpdateCookiesRequest):
    try:
        success = ScraperService.update_cookies(request.cookies)
        if not success:
            raise HTTPException(status_code=400, detail="Invalid cookies JSON or file write failed")
        return {"message": "Facebook cookies updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

