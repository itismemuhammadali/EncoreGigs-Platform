import time
import uuid
import os
from typing import Optional
from firebase_admin import storage
from google.cloud import storage as gcs
from google.auth.credentials import AnonymousCredentials

class StorageService:
    @staticmethod
    def get_upload_path(user_id: str, file_type: str, original_filename: Optional[str] = None):
        """
        Generates a standardized storage path based on user and file type.
        """
        timestamp = int(time.time())
        unique_id = uuid.uuid4().hex[:8]
        extension = original_filename.split('.')[-1] if original_filename and '.' in original_filename else ""
        
        if not extension:
            # Fallback extensions
            ext_map = {
                "image": "jpg",
                "video": "mp4",
                "audio": "mp3",
                "document": "pdf"
            }
            extension = ext_map.get(file_type, "bin")

        if file_type == "profile_photo":
            return f"profile_photos/{user_id}/{timestamp}_{unique_id}.{extension}"
        elif file_type == "portfolio_image":
            return f"portfolios/{user_id}/images/{timestamp}_{unique_id}.{extension}"
        elif file_type == "portfolio_video":
            return f"portfolios/{user_id}/videos/{timestamp}_{unique_id}.{extension}"
        elif file_type == "portfolio_audio":
            return f"portfolios/{user_id}/audio/{timestamp}_{unique_id}.{extension}"
        elif file_type == "application_attachment":
            return f"applications/{user_id}/attachments/{timestamp}_{unique_id}.{extension}"
        else:
            return f"misc/{user_id}/{timestamp}_{unique_id}.{extension}"

    @staticmethod
    def upload_file(file_data: bytes, path: str, content_type: str):
        """
        Uploads file data to Firebase Storage and returns the URL.
        """
        try:
            print(f"DEBUG: Starting upload to path: {path}")
            bucket_name = 'onlygigz-33557.firebasestorage.app'
            
            # If in emulator mode, use direct client with AnonymousCredentials
            if os.getenv("FIREBASE_STORAGE_EMULATOR_HOST"):
                print(f"DEBUG: Using Anonymous Storage Client for emulator")
                emulator_host = os.getenv("FIREBASE_STORAGE_EMULATOR_HOST")
                client = gcs.Client(
                    project='demo-onlygigz',
                    credentials=AnonymousCredentials(),
                    client_options={"api_endpoint": f"http://{emulator_host}"}
                )
                bucket = client.bucket(bucket_name)
            else:
                # Production mode
                bucket = storage.bucket(bucket_name)
            
            blob = bucket.blob(path)
            blob.upload_from_string(file_data, content_type=content_type)
            print(f"DEBUG: Data uploaded successfully")
            
            # Construct URL for emulator or production
            if os.getenv("FIREBASE_STORAGE_EMULATOR_HOST"):
                host = os.getenv("FIREBASE_STORAGE_EMULATOR_HOST")
                import urllib.parse
                safe_path = urllib.parse.quote(path, safe='')
                url = f"http://{host}/v0/b/{bucket_name}/o/{safe_path}?alt=media"
                return url
            
            blob.make_public()
            return blob.public_url
        except Exception as e:
            print(f"DEBUG: Exception in StorageService.upload_file: {str(e)}")
            import traceback
            traceback.print_exc()
            raise e

    @staticmethod
    def get_signed_url(path: str):
        """
        Note: In a real app with Firebase Admin, we would use bucket.blob(path).generate_signed_url(...)
        For now, we return the path or a placeholder if using emulator.
        """
        return path
