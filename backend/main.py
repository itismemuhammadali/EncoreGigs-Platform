from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.routers import auth, gigs, bookings, chat, reviews, security, reports, scraper, disputes, notifications, admin_notifications, featured, support, calendar
from backend.payments.router import router as payments_router
import uvicorn
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="OnlyGigz API")

# Configure CORS
origins = [
    "https://admin.onlygigz.app",
    "https://onlygigz.app",
    "https://www.onlygigz.app",
    "http://localhost:3000",
    "http://localhost:8000",
    "http://127.0.0.1:3000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_origin_regex=r"https://.*onlygigz\.app",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(gigs.router)
app.include_router(bookings.router)
app.include_router(chat.router)
app.include_router(reviews.router)
app.include_router(security.router)
app.include_router(reports.router)
app.include_router(scraper.router)
app.include_router(disputes.router)
app.include_router(notifications.router)
app.include_router(admin_notifications.router)
app.include_router(featured.router)
app.include_router(support.router)
app.include_router(calendar.router)
app.include_router(payments_router)

@app.get("/")
async def root():
    return {"message": "OnlyGigz Backend API is running"}

if __name__ == "__main__":
    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=True)
