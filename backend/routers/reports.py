from fastapi import APIRouter, HTTPException, Depends
from backend.services.report_service import ReportService
from typing import Dict, Any

router = APIRouter(prefix="/reports", tags=["Reports"])

@router.get("/dashboard")
async def get_dashboard_analytics():
    try:
        analytics = ReportService.get_dashboard_analytics()
        return analytics
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
