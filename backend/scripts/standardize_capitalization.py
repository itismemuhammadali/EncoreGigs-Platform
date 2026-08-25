import sys
import os

# Add root directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from backend.database import db
from backend.utils.text_utils import capitalize_words, capitalize_list

def migrate_gigs():
    print("Standardizing capitalization for 'gigs' collection...")
    docs = db.collection("gigs").get()
    updated_count = 0
    for doc in docs:
        data = doc.to_dict() or {}
        updates = {}
        
        old_title = data.get("title", "")
        if old_title:
            new_title = capitalize_words(old_title)
            if new_title != old_title:
                updates["title"] = new_title

        old_loc = data.get("location", "")
        if old_loc:
            new_loc = capitalize_words(old_loc)
            if new_loc != old_loc:
                updates["location"] = new_loc

        old_org = data.get("organizerName", "")
        if old_org:
            new_org = capitalize_words(old_org)
            if new_org != old_org:
                updates["organizerName"] = new_org

        old_genres = data.get("genres", [])
        if isinstance(old_genres, list) and old_genres:
            new_genres = capitalize_list(old_genres)
            if new_genres != old_genres:
                updates["genres"] = new_genres

        if updates:
            doc.reference.update(updates)
            updated_count += 1
            print(f"Updated gig [{doc.id}]: {updates}")

    print(f"Finished 'gigs' migration. Total updated: {updated_count}/{len(docs)}")

def migrate_scraped_gigs():
    print("\nStandardizing capitalization for 'scraped_gigs' collection...")
    docs = db.collection("scraped_gigs").get()
    updated_count = 0
    for doc in docs:
        data = doc.to_dict() or {}
        updates = {}

        old_title = data.get("title", "")
        if old_title:
            new_title = capitalize_words(old_title)
            if new_title != old_title:
                updates["title"] = new_title

        old_loc = data.get("location", "")
        if old_loc:
            new_loc = capitalize_words(old_loc)
            if new_loc != old_loc:
                updates["location"] = new_loc

        if updates:
            doc.reference.update(updates)
            updated_count += 1
            print(f"Updated scraped_gig [{doc.id}]: {updates}")

    print(f"Finished 'scraped_gigs' migration. Total updated: {updated_count}/{len(docs)}")

if __name__ == "__main__":
    migrate_gigs()
    migrate_scraped_gigs()
