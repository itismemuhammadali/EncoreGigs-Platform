from google.cloud import firestore as gc_firestore
from backend.database import db
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional
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
            terminal_runs = []
            for r in runs:
                r_data = r.to_dict() or {}
                if r_data.get("status") in ["success", "failed"]:
                    terminal_runs.append(r_data)

            successful_runs = len([r for r in terminal_runs if r.get("status") == "success"])
            success_rate = (successful_runs / len(terminal_runs) * 100) if len(terminal_runs) > 0 else 0
            
            duplicates = len([g for g in gigs if (g.to_dict() or {}).get("flags") == "Duplicate"])
            spam = len([g for g in gigs if (g.to_dict() or {}).get("flags") == "Spam"])
            
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
            runs = db.collection("scraper_runs").order_by("timestamp", direction=gc_firestore.Query.DESCENDING).limit(limit).get()
            formatted_runs = []
            for doc in runs:
                data = doc.to_dict() or {}
                timestamp = data.get("timestamp")
                formatted_runs.append({
                    "id": doc.id,
                    "timestamp": timestamp.isoformat() if timestamp and hasattr(timestamp, "isoformat") else "N/A",
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
    def get_imported_gigs(limit: int = 2000, filter_type: str = "all"):
        """Fetch recently imported gigs from the scraped_gigs collection."""
        try:
            query = db.collection("scraped_gigs").order_by("updatedAt", direction=gc_firestore.Query.DESCENDING)
            docs = query.get() 
            
            gigs = []
            for doc in docs:
                data = doc.to_dict() or {}
                flags = data.get("flags", "None")

                if filter_type == "duplicates" and flags != "Duplicate": continue
                if filter_type == "spam" and flags != "Spam": continue
                
                important_fields = [data.get("title"), data.get("description"), data.get("date"), data.get("location"), data.get("sourceUrl")]
                filled_fields = [f for f in important_fields if f and str(f).lower() not in ["not specified", "none", "unknown"]]
                confidence = int((len(filled_fields) / len(important_fields)) * 100)
                
                classification = "Jazz" if "jazz" in str(data.get("description", "")).lower() else "Rock"
                if flags == "Spam": classification = "Suspicious"

                created_at = data.get("updatedAt") or data.get("createdAt")
                imported_at = created_at.isoformat() if created_at and hasattr(created_at, 'isoformat') else "Unknown"

                organizer_data = data.get("organizer", {}) if isinstance(data.get("organizer"), dict) else {}
                organizer_profile = data.get("organizerProfileUrl") or data.get("organizer_profile_url") or data.get("posterUrl") or data.get("poster_url") or organizer_data.get("profile_url") or organizer_data.get("website") or ""

                source_url = data.get("sourceUrl") or data.get("source_url") or data.get("postUrl") or data.get("post_url") or data.get("permalink") or data.get("url") or data.get("link") or ""

                contact_email = data.get("contactEmail") or data.get("externalContactEmail") or organizer_data.get("personal_email") or organizer_data.get("business_email") or ""
                contact_phone = data.get("contactPhone") or data.get("externalContactPhone") or organizer_data.get("personal_phone") or organizer_data.get("business_phone") or ""

                gigs.append({
                    "id": doc.id,
                    "title": data.get("title", "Untitled"),
                    "source": data.get("sourceType", "Unknown"),
                    "sourceUrl": source_url,
                    "organizerProfileUrl": organizer_profile,
                    "contactEmail": contact_email,
                    "contactPhone": contact_phone,
                    "budget": data.get("budget", ""),
                    "location": data.get("location", ""),
                    "date": data.get("date", ""),
                    "duration": data.get("duration", ""),
                    "description": data.get("description", ""),
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
            import shutil
            current_file = os.path.abspath(__file__)
            root_dir = os.path.dirname(os.path.dirname(os.path.dirname(current_file)))
            scraper_path = os.path.join(root_dir, "scraper", "main.py")
            log_path = os.path.join(root_dir, "scraper_debug.log")
            
            cmd = [sys.executable, scraper_path]
            if shutil.which("xvfb-run"):
                cmd = ["xvfb-run"] + cmd

            subprocess.Popen(
                cmd,
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
            raw_data = doc.to_dict() if hasattr(doc, "to_dict") and getattr(doc, "exists", False) else None
            if not isinstance(raw_data, dict):
                return None
            data: dict[str, Any] = raw_data

            organizer_data = data.get("organizer", {}) if isinstance(data.get("organizer"), dict) else {}
            contact_email = data.get("contactEmail") or data.get("externalContactEmail") or organizer_data.get("personal_email") or organizer_data.get("business_email") or organizer_data.get("email") or ""

            if not contact_email:
                import re
                full_text = f"{data.get('title', '')} {data.get('description', '')}"
                emails_found = re.findall(r'[\w\.-]+@[\w\.-]+\.\w+', full_text)
                if emails_found:
                    contact_email = emails_found[0]

            from backend.utils.text_utils import capitalize_words, capitalize_list

            gig_data = {
                "title": capitalize_words(data.get("title", "")),
                "description": data.get("description", ""),
                "requirements": data.get("requirements", []) if isinstance(data.get("requirements"), list) else [],
                "genres": capitalize_list(data.get("genres", []) if isinstance(data.get("genres"), list) else []),
                "date": data.get("date", ""),
                "time": data.get("time", ""),
                "expiryDate": data.get("expiryDate") or data.get("date", ""),
                "budget": data.get("budget", ""),
                "location": capitalize_words(data.get("location", "")),
                "organizerId": "scraped",
                "organizer_id": "scraped",
                "organizerName": "Gig Lead",
                "organizerImage": organizer_data.get("profile_image_url", ""),
                "contactEmail": contact_email,
                "organizerEmail": contact_email,
                "externalContactEmail": contact_email,
                "organizerProfileUrl": data.get("organizerProfileUrl") or organizer_data.get("profile_url") or "",
                "imageUrl": data.get("imageUrl", ""),
                "duration": data.get("duration", ""),
                "isUrgent": False,
                "status": "open",
                "applicantsCount": 0,
                "isScraped": True,
                "sourceUrl": data.get("sourceUrl", ""),
                "sourceType": data.get("sourceType", ""),
                "createdAt": gc_firestore.SERVER_TIMESTAMP
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
                data = doc.to_dict() or {}
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

    @staticmethod
    def get_sources():
        """Fetch all scraper sources from Firestore scraper_sources collection."""
        try:
            docs = db.collection("scraper_sources").get()
            sources = []
            for doc in docs:
                data = doc.to_dict() or {}
                added_at = data.get("addedAt", "")
                sources.append({
                    "id": doc.id,
                    "url": data.get("url", ""),
                    "name": data.get("name", "Facebook Group"),
                    "type": data.get("type", "facebook_group"),
                    "enabled": data.get("enabled", True),
                    "addedAt": added_at.isoformat() if hasattr(added_at, "isoformat") else str(added_at)
                })
            return sources
        except Exception as e:
            print(f"Error getting scraper sources: {e}")
            return []

    @staticmethod
    def add_source(url: str, name: str = "Facebook Group", source_type: str = "facebook_group"):
        """Add a new scraper source (Facebook Group) to Firestore."""
        try:
            source_ref = db.collection("scraper_sources").document()
            source_ref.set({
                "url": url,
                "name": name,
                "type": source_type,
                "enabled": True,
                "addedAt": gc_firestore.SERVER_TIMESTAMP
            })
            return {"id": source_ref.id, "url": url, "name": name, "type": source_type}
        except Exception as e:
            print(f"Error adding scraper source: {e}")
            return None

    @staticmethod
    def delete_source(source_id: str):
        """Delete a scraper source by ID."""
        try:
            db.collection("scraper_sources").document(source_id).delete()
            return True
        except Exception as e:
            print(f"Error deleting scraper source: {e}")
            return False

    @staticmethod
    def update_cookies(cookies_content: str):
        """Save updated Facebook cookies JSON to scraper/facebook_cookies.json."""
        try:
            import json
            current_file = os.path.abspath(__file__)
            root_dir = os.path.dirname(os.path.dirname(os.path.dirname(current_file)))
            cookies_path = os.path.join(root_dir, "scraper", "facebook_cookies.json")
            
            parsed = json.loads(cookies_content)
            with open(cookies_path, "w", encoding="utf-8") as f:
                json.dump(parsed, f, indent=2)
            return True
        except Exception as e:
            print(f"Error updating cookies file: {e}")
            return False

