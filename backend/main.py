from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.routers import auth, gigs, bookings, chat, reviews, security, reports, scraper, disputes
from backend.payments.router import router as payments_router
import uvicorn
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="OnlyGigz API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:3001",
        "http://127.0.0.1:3001",
        "http://192.168.100.55:3000",
        "http://192.168.100.55:3001",
        "http://192.168.100.55:8000",
        "http://177.7.32.116",
        "http://177.7.32.116:8000",
    ],
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
app.include_router(payments_router)

@app.get("/")
async def root():
    return {"message": "OnlyGigz Backend API is running"}

if __name__ == "__main__":
    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=True)
