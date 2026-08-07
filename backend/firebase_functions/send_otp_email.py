"""
Firebase Cloud Function to send OTP emails using Firebase Admin SDK.
Deploy with: firebase deploy --only functions:sendOtpEmail
"""

import functions_framework
from firebase_admin import initialize_app, firestore
import google.cloud.logging
import json

# Initialize Firebase
initialize_app()
db = firestore.client()

@functions_framework.http
def send_otp_email(request):
    """HTTP Cloud Function to send OTP email."""
    
    # Handle CORS
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST',
            'Access-Control-Allow-Headers': 'Content-Type',
        }
        return ('', 204, headers)
    
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json',
    }
    
    try:
        request_json = request.get_json()
        email = request_json.get('email')
        otp_code = request_json.get('otp_code')
        uid = request_json.get('uid')
        
        if not email or not otp_code or not uid:
            return (json.dumps({'error': 'Missing required fields'}), 400, headers)
        
        # Prepare email data for Firebase email sending
        # Using Firestore to store email task for Cloud Function to process
        email_doc = db.collection('email_queue').document()
        email_doc.set({
            'to': email,
            'subject': 'OnlyGigz - Your Verification Code',
            'uid': uid,
            'otp_code': otp_code,
            'timestamp': firestore.SERVER_TIMESTAMP,
            'status': 'pending',
            'html': f"""
            <html>
                <body style="font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 20px;">
                    <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                        <h2 style="color: #333; margin-bottom: 20px;">OnlyGigz Verification</h2>
                        <p style="color: #666; font-size: 16px; margin-bottom: 20px;">Your one-time verification code is:</p>
                        <div style="background-color: #0A0A0F; padding: 30px; text-align: center; border-radius: 8px; margin: 30px 0;">
                            <h1 style="letter-spacing: 8px; color: #A1F301; font-family: monospace; font-size: 48px; margin: 0;">{otp_code}</h1>
                        </div>
                        <p style="color: #666; font-size: 14px; margin: 20px 0;">This code will expire in <strong>10 minutes</strong>.</p>
                        <p style="color: #666; font-size: 14px; margin: 20px 0;">If you did not request this code, please ignore this email.</p>
                        <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
                        <p style="color: #999; font-size: 12px; margin: 0;">OnlyGigz - Where Music Meets Opportunity</p>
                    </div>
                </body>
            </html>
            """
        })
        
        print(f"✅ Email queued for sending to {email} with OTP {otp_code}")
        
        return (json.dumps({
            'success': True,
            'message': 'Email queued for delivery',
            'doc_id': email_doc.id
        }), 200, headers)
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return (json.dumps({'error': str(e)}), 500, headers)
