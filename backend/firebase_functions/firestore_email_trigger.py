"""
Firebase Cloud Function triggered on Firestore write to send emails.
This function watches the email_queue collection and sends emails via Sendgrid or Firebase email service.

Deploy with: firebase deploy --only functions:onEmailQueued
"""

import functions_framework
from firebase_admin import initialize_app, firestore
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
import json
from datetime import datetime

# Initialize Firebase
initialize_app()
db = firestore.client()

@functions_framework.cloud_event
def on_email_queued(cloud_event):
    """Triggered when email is added to email_queue collection."""
    
    # Extract Firestore document data
    firestore_doc = cloud_event.data["value"]["fields"]
    
    try:
        to_email = firestore_doc.get('to', {}).get('stringValue', '')
        subject = firestore_doc.get('subject', {}).get('stringValue', '')
        html_content = firestore_doc.get('html', {}).get('stringValue', '')
        otp_code = firestore_doc.get('otp_code', {}).get('stringValue', '')
        uid = firestore_doc.get('uid', {}).get('stringValue', '')
        
        if not to_email:
            print("❌ No email address found")
            return
        
        # Get Gmail credentials
        gmail_user = os.getenv("GMAIL_EMAIL", "")
        gmail_password = os.getenv("GMAIL_APP_PASSWORD", "")
        
        if not gmail_user or not gmail_password:
            print(f"⚠️  Gmail credentials not set. Email queued but not sent.")
            print(f"Set GMAIL_EMAIL and GMAIL_APP_PASSWORD in environment variables.")
            return
        
        # Create email message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = gmail_user
        msg['To'] = to_email
        
        # Attach HTML content
        msg.attach(MIMEText(html_content, 'html'))
        
        # Send via Gmail SMTP
        server = smtplib.SMTP_SSL('smtp.gmail.com', 465)
        server.login(gmail_user, gmail_password)
        server.sendmail(gmail_user, to_email, msg.as_string())
        server.quit()
        
        print(f"✅ Email sent to {to_email} with OTP {otp_code}")
        
        # Update status in Firestore
        db.collection('email_queue').document(cloud_event.data["value"]["name"].split('/')[-1]).update({
            'status': 'sent',
            'sent_at': firestore.SERVER_TIMESTAMP
        })
        
    except smtplib.SMTPAuthenticationError as e:
        print(f"❌ SMTP Authentication failed: {e}")
        print(f"Check your GMAIL_EMAIL and GMAIL_APP_PASSWORD")
    except Exception as e:
        print(f"❌ Error sending email: {str(e)}")
