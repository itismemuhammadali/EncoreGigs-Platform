from datetime import datetime, timedelta, timezone
from typing import Optional
from firebase_admin import firestore
from backend.database import db

class FeaturedService:
    @staticmethod
    def purchase_featured(musician_id: str, plan: str, amount: float, payment_token: Optional[str] = None) -> dict:
        now = datetime.now(timezone.utc)
        
        # Calculate duration based on plan
        plan_lower = plan.lower()
        if "24" in plan_lower or "hour" in plan_lower:
            duration = timedelta(hours=24)
            duration_label = "24 Hours"
        elif "30" in plan_lower or "month" in plan_lower:
            duration = timedelta(days=30)
            duration_label = "30 Days"
        else: # Default 7 days
            duration = timedelta(days=7)
            duration_label = "7 Days"

        expiry_dt = now + duration
        
        # Fetch musician details
        musician_ref = db.collection("musicians").document(musician_id)
        musician_doc = musician_ref.get()
        
        musician_name = "Unknown Artist"
        genre = "Music"
        
        if musician_doc.exists:
            mus_data = musician_doc.to_dict() or {}
            musician_name = mus_data.get("name") or mus_data.get("fullName") or mus_data.get("stageName") or "Unknown Artist"
            genres = mus_data.get("genres") or mus_data.get("genre") or []
            if isinstance(genres, list) and genres:
                genre = genres[0]
            elif isinstance(genres, str):
                genre = genres

        # Update musician document
        musician_ref.set({
            "isFeatured": True,
            "featuredUntil": expiry_dt.isoformat(),
            "featuredPlan": duration_label,
            "featuredAmount": amount,
            "updatedAt": firestore.SERVER_TIMESTAMP
        }, merge=True)

        # Format currency string
        amount_str = f"${amount:.2f}".replace(".00", "")

        # Create subscription record
        sub_ref = db.collection("featured_subscriptions").document()
        sub_id = f"FEAT-{sub_ref.id[:6].upper()}"
        
        sub_data = {
            "id": sub_id,
            "musicianId": musician_id,
            "name": musician_name,
            "genre": genre,
            "boostDuration": duration_label,
            "startDate": now.strftime("%Y-%m-%d"),
            "expiryDate": expiry_dt.strftime("%Y-%m-%d"),
            "expiryIso": expiry_dt.isoformat(),
            "amountPaid": amount_str,
            "views": "0",
            "status": "active",
            "createdAt": firestore.SERVER_TIMESTAMP
        }
        
        sub_ref.set(sub_data)
        return sub_data

    @staticmethod
    def get_featured_artists() -> list:
        now = datetime.now(timezone.utc)
        docs = db.collection("featured_subscriptions").stream()
        
        results = []
        for doc in docs:
            data = doc.to_dict()
            # Remove non-serializable fields if present
            if "createdAt" in data:
                del data["createdAt"]
            # Check if expired
            expiry_iso = data.get("expiryIso")
            if expiry_iso:
                try:
                    exp_dt = datetime.fromisoformat(expiry_iso)
                    if exp_dt < now and data.get("status") == "active":
                        data["status"] = "expired"
                        doc.reference.update({"status": "expired"})
                        
                        # Also update musician profile if applicable
                        m_id = data.get("musicianId")
                        if m_id:
                            m_ref = db.collection("musicians").document(m_id)
                            m_doc = m_ref.get()
                            if m_doc.exists:
                                m_data = m_doc.to_dict() or {}
                                m_until = m_data.get("featuredUntil")
                                if m_until:
                                    try:
                                        if datetime.fromisoformat(m_until) < now:
                                            m_ref.update({"isFeatured": False})
                                    except Exception:
                                        m_ref.update({"isFeatured": False})
                except Exception:
                    pass
            results.append(data)
        return results

    @staticmethod
    def revoke_featured(id_or_musician_id: str) -> bool:
        docs = db.collection("featured_subscriptions").where("id", "==", id_or_musician_id).stream()
        found = False
        
        for doc in docs:
            doc.reference.update({"status": "expired"})
            data = doc.to_dict()
            m_id = data.get("musicianId")
            if m_id:
                db.collection("musicians").document(m_id).update({"isFeatured": False})
            found = True

        if not found:
            doc_ref = db.collection("featured_subscriptions").document(id_or_musician_id)
            if doc_ref.get().exists:
                doc_ref.update({"status": "expired"})
                m_id = doc_ref.get().to_dict().get("musicianId")
                if m_id:
                    db.collection("musicians").document(m_id).update({"isFeatured": False})
                found = True
            else:
                m_ref = db.collection("musicians").document(id_or_musician_id)
                if m_ref.get().exists:
                    m_ref.update({"isFeatured": False})
                    found = True

        return found
