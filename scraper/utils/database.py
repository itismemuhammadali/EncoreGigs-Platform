import firebase_admin
from firebase_admin import credentials, firestore
import os
from scraper.models.gig import GigDetails
import google.auth.credentials
from datetime import datetime, timezone

# 0. Mock Credential to bypass ADC check in emulator
class MockCredential(google.auth.credentials.Credentials):
    def refresh(self, request):
        pass

class DatabaseManager:
    def __init__(self):
        use_emulator = os.getenv("SCRAPER_USE_EMULATOR", "false").lower() == "true"
        
        if use_emulator:
            os.environ["FIRESTORE_EMULATOR_HOST"] = "127.0.0.1:8080"
            os.environ["GCLOUD_PROJECT"] = "demo-onlygigz"

        if not firebase_admin._apps:
            if use_emulator:
                private_key = r"""-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAoq//UsKS9Gex2oRn/aOzdEe821k8R5HFzPDQ8PtCCaARDXex
Yv+bp4WY1+tYppEQ7HY1DN4+mHJe3SIS7U1Wjt/C139oJS34C+7S9yZuFQGHcGs7
XqC6FQCmQtfe+Vnz5Px0re6bQ/benBvd1gpWQra/4O78x9AVMKxPIonz1xlckbRe
NRYO06d2yT7VEG14jmq/F0QaGr13C5i6P+csgmNZbhbn+JeQ9WjEoJTY8i6i+L1i
E57b1U+HaOVC39rUXfaDwP6nCKwzegTpfqcdORctj/EmdWFK3ryqDjO3CUtctQ2p
CvdyrbL+k8HhdyyoERc90tnyaLzVl8Fi5VKqVwIDAQABAoIBABChIt0nzHO1IcXv
YN3ZXN+W8aQORA4gxXJEb2cil8Z6GSQiRvySmiuOiWgQw3gLPgqdrqCJGybkEfRS
plKhZCaokrcKa+/Y+hDmMaRXxkrZZCnGnEP48+xvq48Ll9wvKLIQaDDbQf25f1m/
s3ZMijK5kXWBmE8oYvIdut0R8t3arPiux08YN4TjTgXw17fmm1irWy9TQc58CGMM
dqda66yXZ4eoI2ePaHQZvdmtaKC4GmxDHUFqjuBDvLIMmRtSSDOEmJuC7TjMVVdR
dgAHyNS6jNv40mJQ0+2Unl1eKK+QKq06Kn7fTt+VAFwrmECzg22vZZCRST9eohxS
OUM8xFkCgYEA28ejkiMQWpfnP+pqunaGXjCMijbe4oBM2vLUn8VM6Mqr0KDwHU5D
vACR2h129y4HuwBtTJ5TDn2xPqX9kIC8wrcXHkYaqeOOl5RGvRS5oJ+trqObCAyd
8JlG0gsKIy5srJr1J+/rHS8jHR4wmT4d7yiz1C90UbWhnfmyzApm0nsCgYEAvX+r
1Zc37s/+AsZC+kgI1ku6NsLgdFYUeqfiuYkGmhn2vJ48klk0dQSnJk1Wu9Bt3YX+
BGTovRHQnUzjERvYRN38ZYOfD0610AkZV2y5v9ZjW+YLDTUWukoGcz2mJ8GdmWMr
DIyq+QTkLzgyTXJtOOGN+Wc2772esg8VSvF3ftUCgYEAyR4TbPNxT7WaBD87k45K
v36l3QUBSTwnGGUGdX5TNuPf/naHxAmOqkfLMFGuP9t7b4CghHCNiME0pSO4ubdV
BMoO+cElPTnjjoo9gWGpzHbStPE6OU9yaG2bBTLc//zHrdvPY9CE0pwEAe1Sg6j4
M5aHmTAjvXH8h1esalNKbGkCgYBp1jOnwKSJqfspm4fu92qQHY1sZl0sPKOFedzk
WQap7NRktlAIQPBOZwHgH5PQo/GoptyfoahnaNrF8BpmBNI+bGk6XU/qIcDj5yET
NfNslJW7zvjfMIZ4Fz4RAR6a18Vo1P1HLg2TtUqooM9feAhOm5NK9320WoiW1FvF
FqXx3QKBgD/jDQmBdB5DAzxtEG+5mbiSJ8Z9Gyjq2tg33IDkD3WJ3WQIy7NS9iN8
Pev/rtFqXbTGD/UHb3+C8riGXvLWj48Yeu3BwJv3V7lijBKI/onaIsiFeJceNNFY
DF+8i6HTGHXYHNRDzOUWglTl6fwI6nD2XC0QYg+fzc1qw6iqKCh/
-----END RSA PRIVATE KEY-----
"""
                mock_cred = credentials.Certificate({
                    "type": "service_account",
                    "project_id": "demo-onlygigz",
                    "client_email": "dummy@demo-onlygigz.iam.gserviceaccount.com",
                    "token_uri": "https://oauth2.googleapis.com/token",
                    "private_key": private_key
                })
                firebase_admin.initialize_app(mock_cred, {'projectId': 'demo-onlygigz'})
            else:
                cred = credentials.Certificate("backend/serviceAccountKey.json")
                firebase_admin.initialize_app(cred, {
                    'projectId': 'onlygigz-33557',
                    'storageBucket': 'onlygigz-33557.firebasestorage.app'
                })
        
        self.db = firestore.client()
        # --- THE CORRECT COLLECTION ---
        # We save to 'scraped_gigs' to keep them separate from verified/manual gigs.
        self.collection = self.db.collection("scraped_gigs")

    def save_gig(self, gig: GigDetails):
        """Saves a gig to 'scraped_gigs' collection, detecting spam and marking duplicates."""
        try:
            # 1. Basic Spam Detection
            spam_keywords = ["crypto", "sugar daddy", "fast cash", "investment", "earn money", "casino", "poker", "dating"]
            is_spam = any(k in gig.title.lower() or k in gig.description.lower() for k in spam_keywords)
            initial_flag = "Spam" if is_spam else "None"

            # 2. Check if gig already exists in scraped_gigs
            existing = self.collection.where("externalId", "==", gig.external_id).limit(1).get()
            
            if len(existing) > 0:
                doc_id = existing[0].id
                self.collection.document(doc_id).update({
                    "updatedAt": datetime.now(timezone.utc),
                    "flags": "Duplicate" if initial_flag == "None" else "Spam"
                })
                # print(f"Marked as duplicate in scraped_gigs: {gig.title}", flush=True)
                return 2

            # 3. Save as New Scraped Gig
            data = gig.dict()
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
                "status": "pending",
                "flags": initial_flag,
                "createdAt": datetime.now(timezone.utc),
                "updatedAt": datetime.now(timezone.utc),
                "organizer": data["organizer"]
            }

            self.collection.add(firestore_data)
            print(f"Saved to scraped_gigs: {gig.title} (Flag: {initial_flag})", flush=True)
            return 1
        except Exception as e:
            print(f"Error saving to Firestore: {e}", flush=True)
            return 0

    def log_run(self, source: str, imported: int, duplicates: int, errors: int, duration: float, status: str, run_id: str = None):
        """Logs a scraper run to Firestore. Updates if run_id is provided."""
        try:
            run_data = {
                "timestamp": datetime.now(timezone.utc),
                "source": source,
                "imported": imported,
                "duplicates": duplicates,
                "errors": errors,
                "duration": f"{int(duration // 60)}m {int(duration % 60)}s",
                "status": status
            }
            
            if run_id:
                self.db.collection("scraper_runs").document(run_id).update(run_data)
                return run_id
            else:
                _, doc_ref = self.db.collection("scraper_runs").add(run_data)
                return doc_ref.id
        except Exception as e:
            print(f"Error logging run to Firestore: {e}", flush=True)
            return None
