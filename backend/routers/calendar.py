from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from backend.models.calendar_models import CalendarEventCreate, CalendarEventResponse
from firebase_admin import firestore

router = APIRouter(prefix="/calendar", tags=["calendar"])

@router.get("/events/{user_id}", response_model=List[CalendarEventResponse])
async def get_user_calendar_events(user_id: str):
    try:
        db = firestore.client()
        docs = db.collection("calendar_events").where("userId", "==", user_id).stream()
        events = []
        for doc in docs:
            data = doc.to_dict()
            data["id"] = doc.id
            events.append(data)
        return events
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/events", response_model=CalendarEventResponse)
async def create_calendar_event(event: CalendarEventCreate):
    try:
        db = firestore.client()
        event_dict = event.dict()
        doc_ref = db.collection("calendar_events").add(event_dict)
        event_dict["id"] = doc_ref[1].id
        return event_dict
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
