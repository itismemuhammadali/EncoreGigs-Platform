import firebase_admin
from firebase_admin import credentials, firestore
import os
from scraper.models.gig import GigDetails

class DatabaseManager:
    def __init__(self):
        # Initialize Firestore (assuming we're running in the same environment as backend)
        # Using environment variables from backend/database.py if available
        os.environ["FIRESTORE_EMULATOR_HOST"] = "127.0.0.1:8080"
        os.environ["GCLOUD_PROJECT"] = "demo-onlygigz"

        if not firebase_admin._apps:
            # For local demo/emulator
            firebase_admin.initialize_app(options={'projectId': 'demo-onlygigz'})
        
        self.db = firestore.client()
        self.collection = self.db.collection("gigs")

    def save_gig(self, gig: GigDetails):
        """Saves a gig to Firestore, avoiding duplicates."""
        try:
            # Check if gig already exists by external_id
            existing = self.collection.where("externalId", "==", gig.external_id).limit(1).get()
            if len(existing) > 0:
                print(f"Skipping duplicate: {gig.title}")
                return

            # Convert Pydantic model to dict for Firestore
            data = gig.dict()
            
            # Map model names to Firestore schema (camelCase)
            firestore_data = {
                "title": data["title"],
                "description": data["description"],
                "location": data["location"],
                "budget": data["budget"],
                "date": data["date"],
                "time": data["time"],
                "imageUrl": data["image_url"],
                "sourceUrl": data["source_url"],
                "sourceType": data["source_type"],
                "externalId": data["external_id"],
                "isScraped": True,
                "status": "active",
                "createdAt": firestore.SERVER_TIMESTAMP,
                "organizer": data["organizer"]
            }

            self.collection.add(firestore_data)
            print(f"Saved to DB: {gig.title}")
        except Exception as e:
            print(f"Error saving to Firestore: {e}")
