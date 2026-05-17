from firebase_admin import firestore
from backend.database import db
from typing import List, Optional

class ReviewService:
    @staticmethod
    def get_all_reviews():
        reviews_docs = db.collection("reviews").order_by("createdAt", direction=firestore.Query.DESCENDING).get()
        reviews = []
        
        # Cache for musician and organizer details to avoid redundant database calls
        musician_cache = {}
        organizer_cache = {}
        
        for doc in reviews_docs:
            review_data = doc.to_dict()
            review_id = doc.id
            
            musician_id = review_data.get("musicianId")
            booking_id = review_data.get("bookingId")
            
            # Fetch musician name
            musician_name = "Unknown Musician"
            if musician_id:
                if musician_id not in musician_cache:
                    m_doc = db.collection("musicians").document(musician_id).get()
                    if m_doc.exists:
                        m_data = m_doc.to_dict()
                        musician_cache[musician_id] = m_data.get("fullName") or m_data.get("name") or "Unknown Musician"
                    else:
                        musician_cache[musician_id] = "Deleted Musician"
                musician_name = musician_cache[musician_id]
                
            # Fetch organizer name from booking
            organizer_name = "Anonymous"
            if booking_id:
                if booking_id not in organizer_cache:
                    b_doc = db.collection("bookings").document(booking_id).get()
                    if b_doc.exists:
                        b_data = b_doc.to_dict()
                        organizer_id = b_data.get("organizerId")
                        if organizer_id:
                            o_doc = db.collection("organizers").document(organizer_id).get()
                            if o_doc.exists:
                                o_data = o_doc.to_dict()
                                organizer_cache[booking_id] = o_data.get("name") or o_data.get("orgName") or "Anonymous"
                            else:
                                organizer_cache[booking_id] = "Anonymous"
                        else:
                            organizer_cache[booking_id] = "Anonymous"
                    else:
                        organizer_cache[booking_id] = "Anonymous"
                organizer_name = organizer_cache[booking_id]
            
            # Format date
            date_str = ""
            created_at = review_data.get("createdAt")
            if created_at:
                try:
                    # If it's a datetime object from firestore
                    date_str = created_at.strftime("%Y-%m-%d")
                except:
                    date_str = str(created_at)

            reviews.append({
                "id": review_id,
                "musicianName": musician_name,
                "rating": float(review_data.get("rating", 0)),
                "organizer": organizer_name,
                "gigReference": review_data.get("gigTitle", "Event"),
                "date": date_str,
                "content": review_data.get("reviewText", ""),
                "isFlagged": review_data.get("isFlagged", False)
            })
            
        return reviews

    @staticmethod
    def get_review_stats():
        reviews = db.collection("reviews").get()
        total = len(reviews)
        
        if total == 0:
            return {
                "total": 0,
                "average": "0.0",
                "fiveStars": 0,
                "flagged": 0
            }
            
        total_rating = 0
        five_stars = 0
        flagged = 0
        
        for doc in reviews:
            data = doc.to_dict()
            rating = float(data.get("rating", 0))
            total_rating += rating
            if rating == 5.0:
                five_stars += 1
            if data.get("isFlagged", False):
                flagged += 1
                
        return {
            "total": total,
            "average": str(round(total_rating / total, 1)),
            "fiveStars": five_stars,
            "flagged": flagged
        }

    @staticmethod
    def toggle_flag(review_id: str, is_flagged: bool):
        review_ref = db.collection("reviews").document(review_id)
        if not review_ref.get().exists:
            return False
        review_ref.update({"isFlagged": is_flagged})
        return True

    @staticmethod
    def delete_review(review_id: str):
        review_ref = db.collection("reviews").document(review_id)
        if not review_ref.get().exists:
            return False
        review_ref.delete()
        return True
