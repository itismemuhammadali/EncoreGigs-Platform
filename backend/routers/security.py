from fastapi import APIRouter, HTTPException, Query
from backend.services.security_service import SecurityService
from typing import List

router = APIRouter(prefix="/security", tags=["security"])

@router.get("/logs")
async def get_logs(limit: int = Query(50)):
    try:
        logs = SecurityService.get_logs(limit)
        return logs
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
