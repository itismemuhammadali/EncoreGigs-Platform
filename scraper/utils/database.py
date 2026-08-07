from google.cloud.firestore_v1.base_query import FieldFilter
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
                "organizerProfileUrl": data["organizer"].get("profile_url") or data["organizer"].get("website"),
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

    def get_facebook_sources(self) -> list:
        """Retrieves active Facebook source URLs from Firestore collection 'scraper_sources'.
        Seeds the 50 default Louisiana, Texas, and National Facebook group URLs if empty.
        """
        try:
            sources_ref = self.db.collection("scraper_sources").where(filter=FieldFilter("platform", "==", "facebook")).where(filter=FieldFilter("active", "==", True))
            docs = list(sources_ref.stream())
            if docs:
                urls = [doc.to_dict()["url"] for doc in docs if "url" in doc.to_dict()]
                print(f"Loaded {len(urls)} Facebook group sources from Firestore 'scraper_sources'.", flush=True)
                return urls

            print("No Facebook sources found in Firestore 'scraper_sources'. Seeding default 50 groups...", flush=True)
            return self.seed_default_facebook_sources()
        except Exception as e:
            print(f"Error fetching Facebook sources from Firestore: {e}", flush=True)
            return [s["url"] for s in INITIAL_FACEBOOK_SOURCES]

    def seed_default_facebook_sources(self) -> list:
        """Seeds the 50 default Louisiana, Texas, and National Facebook group URLs into Firestore."""
        seeded_urls = []
        try:
            batch = self.db.batch()
            sources_col = self.db.collection("scraper_sources")
            for item in INITIAL_FACEBOOK_SOURCES:
                doc_id = item["url"].rstrip("/").split("/groups/")[-1]
                doc_ref = sources_col.document(f"fb_{doc_id}")
                doc_data = {
                    "url": item["url"],
                    "slug": doc_id,
                    "platform": "facebook",
                    "region": item.get("region", "General"),
                    "category": item.get("category", "General"),
                    "active": True,
                    "addedAt": datetime.now(timezone.utc)
                }
                batch.set(doc_ref, doc_data, merge=True)
                seeded_urls.append(item["url"])
            batch.commit()
            print(f"Successfully seeded {len(seeded_urls)} Facebook group sources into Firestore.", flush=True)
        except Exception as e:
            print(f"Error seeding Facebook sources to Firestore: {e}", flush=True)
            seeded_urls = [item["url"] for item in INITIAL_FACEBOOK_SOURCES]
        return seeded_urls

    def add_scraper_source(self, url: str, platform: str = "facebook", region: str = "General", category: str = "General") -> bool:
        """Adds a new scraper target source URL to Firestore."""
        try:
            slug = url.rstrip("/").split("/groups/")[-1] if "/groups/" in url else url.rstrip("/").split("/")[-1]
            doc_ref = self.db.collection("scraper_sources").document(f"{platform}_{slug}")
            doc_ref.set({
                "url": url,
                "slug": slug,
                "platform": platform.lower(),
                "region": region,
                "category": category,
                "active": True,
                "addedAt": datetime.now(timezone.utc)
            }, merge=True)
            print(f"Added new {platform} source to Firestore: {url}", flush=True)
            return True
        except Exception as e:
            print(f"Error adding scraper source to Firestore: {e}", flush=True)
            return False

INITIAL_FACEBOOK_SOURCES = [
    # Louisiana
    {"url": "https://www.facebook.com/groups/livemusicinLC/", "region": "Louisiana", "category": "Live Music"},
    {"url": "https://www.facebook.com/groups/louisianamusicians/", "region": "Louisiana", "category": "Musicians"},
    {"url": "https://www.facebook.com/groups/louisianalivemusic/", "region": "Louisiana", "category": "Live Music"},
    {"url": "https://www.facebook.com/groups/louisianabands/", "region": "Louisiana", "category": "Bands"},
    {"url": "https://www.facebook.com/groups/neworleansmusicians/", "region": "Louisiana", "category": "Musicians"},
    {"url": "https://www.facebook.com/groups/batonrougemusicians/", "region": "Louisiana", "category": "Musicians"},
    {"url": "https://www.facebook.com/groups/lafayettemusicians/", "region": "Louisiana", "category": "Musicians"},
    {"url": "https://www.facebook.com/groups/lafayettelivemusic/", "region": "Louisiana", "category": "Live Music"},
    {"url": "https://www.facebook.com/groups/academianlivemusic/", "region": "Louisiana", "category": "Live Music"},
    {"url": "https://www.facebook.com/groups/cajunmusic/", "region": "Louisiana", "category": "Cajun Music"},
    {"url": "https://www.facebook.com/groups/cajunandzydeco/", "region": "Louisiana", "category": "Cajun/Zydeco"},
    {"url": "https://www.facebook.com/groups/louisianamusicscene/", "region": "Louisiana", "category": "Music Scene"},
    {"url": "https://www.facebook.com/groups/louisianalivemusicscene/", "region": "Louisiana", "category": "Live Music Scene"},
    {"url": "https://www.facebook.com/groups/northshorelivemusic/", "region": "Louisiana", "category": "Live Music"},
    {"url": "https://www.facebook.com/groups/shreveportmusicians/", "region": "Louisiana", "category": "Musicians"},
    {"url": "https://www.facebook.com/groups/monroemusicians/", "region": "Louisiana", "category": "Musicians"},
    {"url": "https://www.facebook.com/groups/lakecharlesmusicians/", "region": "Louisiana", "category": "Musicians"},
    {"url": "https://www.facebook.com/groups/louisianafestivals/", "region": "Louisiana", "category": "Festivals"},
    {"url": "https://www.facebook.com/groups/louisianaweddingvendors/", "region": "Louisiana", "category": "Weddings"},
    {"url": "https://www.facebook.com/groups/louisianaeventplanners/", "region": "Louisiana", "category": "Events"},

    # Texas
    {"url": "https://www.facebook.com/groups/texaslivemusic/", "region": "Texas", "category": "Live Music"},
    {"url": "https://www.facebook.com/groups/texasmusicians/", "region": "Texas", "category": "Musicians"},
    {"url": "https://www.facebook.com/groups/texascountrymusic/", "region": "Texas", "category": "Country Music"},
    {"url": "https://www.facebook.com/groups/dfwlocalmusic/", "region": "Texas", "category": "DFW Local Music"},
    {"url": "https://www.facebook.com/groups/dallascovermusicians/", "region": "Texas", "category": "Cover Bands"},
    {"url": "https://www.facebook.com/groups/texasnightlife/", "region": "Texas", "category": "Nightlife"},
    {"url": "https://www.facebook.com/groups/austinmusicians/", "region": "Texas", "category": "Austin Musicians"},
    {"url": "https://www.facebook.com/groups/austinmusicscene/", "region": "Texas", "category": "Austin Music Scene"},
    {"url": "https://www.facebook.com/groups/houstonmusicians/", "region": "Texas", "category": "Houston Musicians"},
    {"url": "https://www.facebook.com/groups/houstonlivemusic/", "region": "Texas", "category": "Houston Live Music"},
    {"url": "https://www.facebook.com/groups/sanantoniomusicians/", "region": "Texas", "category": "San Antonio Musicians"},
    {"url": "https://www.facebook.com/groups/corpuschristimusicians/", "region": "Texas", "category": "Corpus Christi Musicians"},
    {"url": "https://www.facebook.com/groups/rockportmusicians/", "region": "Texas", "category": "Rockport Musicians"},
    {"url": "https://www.facebook.com/groups/easttexasmusicians/", "region": "Texas", "category": "East Texas Musicians"},
    {"url": "https://www.facebook.com/groups/beaumontmusicians/", "region": "Texas", "category": "Beaumont Musicians"},
    {"url": "https://www.facebook.com/groups/portarthurmusicians/", "region": "Texas", "category": "Port Arthur Musicians"},
    {"url": "https://www.facebook.com/groups/texasbands/", "region": "Texas", "category": "Bands"},
    {"url": "https://www.facebook.com/groups/texasmusicnetwork/", "region": "Texas", "category": "Music Network"},
    {"url": "https://www.facebook.com/groups/texasmusicscene/", "region": "Texas", "category": "Music Scene"},
    {"url": "https://www.facebook.com/groups/reddirtmusic/", "region": "Texas", "category": "Red Dirt Music"},
    {"url": "https://www.facebook.com/groups/texasfestivalmusic/", "region": "Texas", "category": "Festivals"},

    # National Gig Groups
    {"url": "https://www.facebook.com/groups/diytourpostings/", "region": "National", "category": "DIY Tour"},
    {"url": "https://www.facebook.com/groups/livemusicbooking/", "region": "National", "category": "Booking"},
    {"url": "https://www.facebook.com/groups/musicianswanted/", "region": "National", "category": "Musicians Wanted"},
    {"url": "https://www.facebook.com/groups/bandslookingformusicians/", "region": "National", "category": "Bands Seeking Musicians"},
    {"url": "https://www.facebook.com/groups/giggingmusicians/", "region": "National", "category": "Gigging Musicians"},
    {"url": "https://www.facebook.com/groups/themusiciansnetwork/", "region": "National", "category": "Musicians Network"},
    {"url": "https://www.facebook.com/groups/independentmusicartists/", "region": "National", "category": "Independent Artists"},
    {"url": "https://www.facebook.com/groups/apromoterslife/", "region": "National", "category": "Promoters"},
    {"url": "https://www.facebook.com/groups/coverbandcentral/", "region": "National", "category": "Cover Bands"},
]

