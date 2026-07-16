from firebase_admin import firestore
from backend.database import db
from datetime import datetime, timedelta, timezone
import subprocess
import os

class ScraperService:
    @staticmethod
    def get_stats():
        """Fetch overall scraper statistics from scraped_gigs."""
        try:
            gigs = db.collection("scraped_gigs").get()
            total_scraped = len(gigs)
            
            runs = db.collection("scraper_runs").get()
            total_runs_count = len(runs)
            # Only count terminal statuses for success rate calculation
            terminal_runs = [r.to_dict() for r in runs if r.to_dict().get("status") in ["success", "failed"]]
            successful_runs = len([r for r in terminal_runs if r.get("status") == "success"])
            
            success_rate = (successful_runs / len(terminal_runs) * 100) if len(terminal_runs) > 0 else 0
            
            # Real flags from the scraped_gigs collection
            duplicates = len([g for g in gigs if g.to_dict().get("flags") == "Duplicate"])
            spam = len([g for g in gigs if g.to_dict().get("flags") == "Spam"])
            
            return [
                {"label": "Total Scraped Gigs", "value": f"{total_scraped:,}", "subtext": "Unique items found", "icon": "Database"},
                {"label": "Success Rate", "value": f"{success_rate:.1f}%", "trend": "+2.3%", "icon": "CheckCircle"},
                {"label": "Duplicates Detected", "value": str(duplicates), "subtext": "In moderation queue", "icon": "FileText"},
                {"label": "Spam Flagged", "value": str(spam), "subtext": "AI detection active", "icon": "AlertTriangle"},
            ]
        except Exception as e:
            print(f"Error getting scraper stats: {e}")
            return []

    @staticmethod
    def get_recent_runs(limit: int = 5):
        """Fetch recent scraper runs."""
        try:
            runs = db.collection("scraper_runs").order_by("timestamp", direction=firestore.Query.DESCENDING).limit(limit).get()
            formatted_runs = []
            for doc in runs:
                data = doc.to_dict()
                timestamp = data.get("timestamp")
                formatted_runs.append({
                    "id": doc.id,
                    "timestamp": timestamp.isoformat() if timestamp else "N/A",
                    "source": data.get("source", "Unknown"),
                    "imported": data.get("imported", 0),
                    "duplicates": data.get("duplicates", 0),
                    "errors": data.get("errors", 0),
                    "duration": data.get("duration", "0m 0s"),
                    "status": data.get("status", "failed")
                })
            return formatted_runs
        except Exception as e:
            print(f"Error getting recent runs: {e}")
            return []

    @staticmethod
    def get_imported_gigs(limit: int = 50, filter_type: str = "all"):
        """Fetch recently imported gigs from the scraped_gigs collection."""
        try:
            # Sort by updatedAt so fresh duplicates jump to the top
            query = db.collection("scraped_gigs").order_by("updatedAt", direction=firestore.Query.DESCENDING)
            
            docs = query.get() 
            
            gigs = []
            for doc in docs:
                data = doc.to_dict()
                flags = data.get("flags", "None")

                # Apply Filtering
                if filter_type == "duplicates" and flags != "Duplicate": continue
                if filter_type == "spam" and flags != "Spam": continue
                
                # Calculate Completeness
                important_fields = [data.get("title"), data.get("description"), data.get("date"), data.get("location"), data.get("sourceUrl")]
                filled_fields = [f for f in important_fields if f and str(f).lower() not in ["not specified", "none", "unknown"]]
                confidence = int((len(filled_fields) / len(important_fields)) * 100)
                
                classification = "Jazz" if "jazz" in data.get("description", "").lower() else "Rock"
                if flags == "Spam": classification = "Suspicious"

                created_at = data.get("updatedAt") or data.get("createdAt")
                imported_at = created_at.isoformat() if created_at and hasattr(created_at, 'isoformat') else "Unknown"

                gigs.append({
                    "id": doc.id,
                    "title": data.get("title", "Untitled"),
                    "source": data.get("sourceType", "Unknown"),
                    "classification": classification,
                    "confidence": f"{confidence}%",
                    "flags": flags,
                    "importedAt": imported_at,
                    "publishedToApp": bool(data.get("publishedToApp", False))
                })
                
                if len(gigs) >= limit: break
                
            return gigs
        except Exception as e:
            print(f"Error getting imported gigs: {e}")
            return []

    @staticmethod
    def run_scraper():
        """Triggers the scraper engine with absolute paths."""
        try:
            import sys
            import os
            current_file = os.path.abspath(__file__)
            root_dir = os.path.dirname(os.path.dirname(os.path.dirname(current_file)))
            scraper_path = os.path.join(root_dir, "scraper", "main.py")
            log_path = os.path.join(root_dir, "scraper_debug.log")
            
            subprocess.Popen(
                [sys.executable, scraper_path],
                cwd=root_dir,
                stdout=open(log_path, "a"),
                stderr=subprocess.STDOUT
            )
            return True
        except Exception as e:
            print(f"Error triggering scraper: {e}")
            return False

    @staticmethod
    def delete_gig(gig_id: str):
        """Deletes a scraped gig."""
        try:
            db.collection("scraped_gigs").document(gig_id).delete()
            return True
        except Exception as e:
            print(f"Error deleting gig: {e}")
            return False

    @staticmethod
    def update_gig(gig_id: str, updates: dict):
        """Updates a scraped gig."""
        try:
            db.collection("scraped_gigs").document(gig_id).update(updates)
            return True
        except Exception as e:
            print(f"Error updating gig: {e}")
            return False

    @staticmethod
    def publish_gig(gig_id: str):
        """Publishes a scraped gig to the main gigs collection so musicians can see it."""
        try:
            doc = db.collection("scraped_gigs").document(gig_id).get()
            if not doc.exists:
                return None
            data = doc.to_dict()

            organizer_data = data.get("organizer", {}) if isinstance(data.get("organizer"), dict) else {}

            gig_data = {
                "title": data.get("title", ""),
                "description": data.get("description", ""),
                "requirements": data.get("requirements", []) if isinstance(data.get("requirements"), list) else [],
                "genres": data.get("genres", []) if isinstance(data.get("genres"), list) else [],
                "date": data.get("date", ""),
                "time": data.get("time", ""),
                "budget": data.get("budget", ""),
                "location": data.get("location", ""),
                "organizerId": "scraped",
                "organizer_id": "scraped",
                "organizerName": organizer_data.get("name", data.get("sourceType", "Scraped")),
                "organizerImage": organizer_data.get("profile_image_url", ""),
                "imageUrl": data.get("imageUrl", ""),
                "duration": data.get("duration", ""),
                "isUrgent": False,
                "status": "open",
                "applicantsCount": 0,
                "isScraped": True,
                "sourceUrl": data.get("sourceUrl", ""),
                "sourceType": data.get("sourceType", ""),
                "createdAt": firestore.SERVER_TIMESTAMP
            }

            gig_ref = db.collection("gigs").document()
            gig_ref.set(gig_data)

            db.collection("scraped_gigs").document(gig_id).update({
                "publishedToApp": True,
                "publishedGigId": gig_ref.id,
                "publishedAt": datetime.now(timezone.utc)
            })

            return gig_ref.id
        except Exception as e:
            print(f"Error publishing gig: {e}")
            return None

    @staticmethod
    def publish_all_unpublished():
        """Publishes all non-duplicate, non-spam scraped gigs that haven't been published yet."""
        try:
            docs = db.collection("scraped_gigs").get()
            count = 0
            already_published = 0
            skipped = 0
            errors = 0
            for doc in docs:
                data = doc.to_dict()
                if data.get("publishedToApp"):
                    already_published += 1
                    continue
                flags = data.get("flags", "None")
                if flags not in ("None", "none", None, ""):
                    skipped += 1
                    continue
                result = ScraperService.publish_gig(doc.id)
                if result:
                    count += 1
                else:
                    errors += 1
            return {"published": count, "alreadyPublished": already_published, "skipped": skipped, "errors": errors}
        except Exception as e:
            print(f"Error publishing all gigs: {e}")
            return {"published": 0, "alreadyPublished": 0, "skipped": 0, "errors": 0}
