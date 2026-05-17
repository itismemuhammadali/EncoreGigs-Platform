import os
import firebase_admin
from firebase_admin import credentials, firestore
import google.auth.credentials
from google.auth.credentials import AnonymousCredentials

# Standard Google Cloud Emulator Environment Variables
os.environ["FIREBASE_AUTH_EMULATOR_HOST"] = "127.0.0.1:9099"
os.environ["FIRESTORE_EMULATOR_HOST"] = "127.0.0.1:8080"
os.environ["FIREBASE_STORAGE_EMULATOR_HOST"] = "127.0.0.1:9199"
os.environ["STORAGE_EMULATOR_HOST"] = "http://127.0.0.1:9199" # Standard GCS variable
os.environ["GCLOUD_PROJECT"] = "demo-onlygigz"

print(f"--- Firebase Initialization ---")
print(f"Auth Emulator: {os.getenv('FIREBASE_AUTH_EMULATOR_HOST')}")
print(f"Firestore Emulator: {os.getenv('FIRESTORE_EMULATOR_HOST')}")
print(f"Storage Emulator: {os.getenv('STORAGE_EMULATOR_HOST')}")
print(f"Project ID: {os.getenv('GCLOUD_PROJECT')}")

# Initialize Firebase Admin for Emulator
if not firebase_admin._apps:
    class MockCreds(google.auth.credentials.Credentials):
        def refresh(self, request):
            pass
            
    firebase_admin.initialize_app(MockCreds(), {
        'projectId': 'demo-onlygigz',
        'storageBucket': 'demo-onlygigz.appspot.com'
    })

db = firestore.client()
