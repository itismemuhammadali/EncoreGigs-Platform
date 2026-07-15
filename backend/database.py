import os
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin with real credentials
if not firebase_admin._apps:
    cred = credentials.Certificate("backend/serviceAccountKey.json")
    
    firebase_admin.initialize_app(cred, {
        'projectId': 'onlygigz-33557',
        'storageBucket': 'onlygigz-33557.firebasestorage.app'
    })

db = firestore.client()
