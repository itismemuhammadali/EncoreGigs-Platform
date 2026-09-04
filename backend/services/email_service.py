import os
import smtplib
from email.message import EmailMessage
from typing import Dict, Optional

class EmailService:
    @staticmethod
    def _get_smtp_config():
        return {
            "server": os.getenv("SMTP_SERVER"),
            "port": int(os.getenv("SMTP_PORT", "587")),
            "username": os.getenv("SMTP_USERNAME"),
            "password": os.getenv("SMTP_PASSWORD"),
            "from_email": os.getenv("SMTP_FROM_EMAIL", "noreply@onlygigz.com")
        }

    @staticmethod
    def send_contract_email(booking: Dict, pdf_content: bytes):
        """
        Sends the signed contract PDF to both the musician and the organizer.
        If SMTP credentials are not configured, it simulates sending by logging to the console.
        """
        config = EmailService._get_smtp_config()
        
        # Get emails from the booking dictionary (we'll ensure these are passed in)
        organizer_email = booking.get("organizerEmail")
        musician_email = booking.get("musicianEmail")
        
        recipients = [email for email in [organizer_email, musician_email] if email]
        
        if not recipients:
            print("EmailService: No recipient emails found for booking contract.")
            return

        gig_title = booking.get("gigTitle", "Gig")
        subject = f"Signed Contract: {gig_title}"
        body = f"""
Hello,

The contract for the gig "{gig_title}" has been successfully signed by both parties.
Please find the official digitally signed PDF contract attached to this email.

Thank you for using OnlyGigz!
"""

        msg = EmailMessage()
        msg['Subject'] = subject
        msg['From'] = config["from_email"]
        msg['To'] = ", ".join(recipients)
        msg.set_content(body)
        
        # Attach the PDF
        msg.add_attachment(
            pdf_content, 
            maintype='application', 
            subtype='pdf', 
            filename=f"OnlyGigz_Contract_{booking.get('id', 'signed')}.pdf"
        )

        # Send Email via SMTP if configured, else print to console
        if config["server"] and config["username"] and config["password"]:
            try:
                with smtplib.SMTP(config["server"], config["port"]) as server:
                    server.starttls()
                    server.login(config["username"], config["password"])
                    server.send_message(msg)
                print(f"EmailService: Successfully sent contract email to {recipients}")
            except Exception as e:
                print(f"EmailService: Failed to send email via SMTP - {e}")
        else:
            # Development fallback
            print("="*50)
            print("EmailService: [SIMULATED EMAIL DELIVERY]")
            print(f"To: {recipients}")
            print(f"Subject: {subject}")
            print("Attachment: PDF file included")
            print("Body:\n" + body)
            print("="*50)

    @staticmethod
    def send_external_applicant_email(
        poster_email: str,
        gig_title: str,
        musician_name: str,
        musician_instrument: str = "Musician",
        cover_message: str = "",
        app_download_url: str = "https://onlygigz.com/download"
    ):
        """
        Sends an email to external gig posters when a verified musician applies on OnlyGigz.
        Includes applicant summary and a call-to-action link to download the OnlyGigz app.
        """
        if not poster_email:
            print("EmailService: No poster_email provided for external applicant notification.")
            return

        config = EmailService._get_smtp_config()
        subject = f"🎵 You have a new applicant for '{gig_title}' on OnlyGigz!"
        
        body = f"""Hello,

Great news! A verified musician has applied for your gig "{gig_title}" on OnlyGigz.

Applicant Overview:
- Name: {musician_name}
- Instrument / Role: {musician_instrument}
{f'- Message: "{cover_message}"' if cover_message else ''}

To view their full profile, listen to demo tracks, and accept or decline this applicant, download the OnlyGigz app here:
{app_download_url}

Best regards,
The OnlyGigz Team
"""

        msg = EmailMessage()
        msg['Subject'] = subject
        msg['From'] = config["from_email"]
        msg['To'] = poster_email
        msg.set_content(body)

        if config["server"] and config["username"] and config["password"]:
            try:
                with smtplib.SMTP(config["server"], config["port"]) as server:
                    server.starttls()
                    server.login(config["username"], config["password"])
                    server.send_message(msg)
                print(f"EmailService: Sent applicant notification email to external poster ({poster_email})")
            except Exception as e:
                print(f"EmailService: Failed to send external applicant email - {e}")
        else:
            print("="*50)
            print(f"EmailService: [SIMULATED EXTERNAL POSTER NOTIFICATION]")
            print(f"To: {poster_email}")
            print(f"Subject: {subject}")
            print("Body:\n" + body)
            print("="*50)

    @staticmethod
    def _get_sendgrid_config():
        api_key = os.getenv("SENDGRID_API_KEY") or os.getenv("TWILIO_SENDGRID_API_KEY")

        if not api_key:
            try:
                from firebase_admin import firestore
                db = firestore.client()
                doc = db.collection("system_config").document("email").get()
                if doc.exists:
                    data = doc.to_dict() if hasattr(doc, 'to_dict') else doc.data() or {}
                    api_key = data.get("sendgrid_api_key") or data.get("sendgridApiKey") or data.get("api_key")
                
                if not api_key:
                    doc2 = db.collection("system_config").document("sendgrid").get()
                    if doc2.exists:
                        data2 = doc2.to_dict() if hasattr(doc2, 'to_dict') else doc2.data() or {}
                        api_key = data2.get("sendgrid_api_key") or data2.get("sendgridApiKey") or data2.get("api_key")
            except Exception as e:
                print(f"EmailService: Firestore SendGrid key lookup note: {e}")

        return {
            "api_key": api_key,
            "from_email": os.getenv("SENDGRID_FROM_EMAIL") or os.getenv("SMTP_FROM_EMAIL", "notifications@onlygigz.app"),
            "from_name": os.getenv("SENDGRID_FROM_NAME", "OnlyGigz Team")
        }

    @staticmethod
    def send_sendgrid_email(
        to_email: str,
        subject: str,
        html_content: str,
        plain_text_content: Optional[str] = None,
        to_name: Optional[str] = None
    ) -> bool:
        """
        Sends an email using Twilio SendGrid v3 Mail Send REST API.
        Returns True if successful, False otherwise.
        """
        config = EmailService._get_sendgrid_config()
        api_key = config["api_key"]
        
        if not api_key:
            print("EmailService [SendGrid]: No SENDGRID_API_KEY found in environment. Simulating delivery...")
            print("=" * 50)
            print(f"To: {to_email}")
            print(f"Subject: {subject}")
            print(f"HTML Content Snippet: {html_content[:200]}...")
            print("=" * 50)
            return True

        url = "https://api.sendgrid.com/v3/mail/send"
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }

        payload = {
            "personalizations": [
                {
                    "to": [
                        {
                            "email": to_email,
                            "name": to_name or to_email.split("@")[0]
                        }
                    ]
                }
            ],
            "from": {
                "email": config["from_email"],
                "name": config["from_name"]
            },
            "subject": subject,
            "content": [
                {
                    "type": "text/html",
                    "value": html_content
                }
            ]
        }

        if plain_text_content:
            payload["content"].insert(0, {
                "type": "text/plain",
                "value": plain_text_content
            })

        try:
            import requests
            response = requests.post(url, headers=headers, json=payload, timeout=10)
            if response.status_code in [200, 201, 202]:
                print(f"EmailService [SendGrid]: Successfully sent email to {to_email}")
                return True
            else:
                print(f"EmailService [SendGrid]: Failed ({response.status_code}) - {response.text}")
                return False
        except Exception as e:
            print(f"EmailService [SendGrid]: Error sending email - {e}")
            return False

    @staticmethod
    def send_account_approved_email(to_email: str, user_name: str = "Valued User") -> bool:
        """
        Sends the 'Your Account Has Been Approved' email notification via Twilio SendGrid.
        """
        subject = "Your OnlyGigz Account Has Been Approved! 🎉"
        
        html_content = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {{ font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f4f6f8; margin: 0; padding: 0; }}
    .container {{ max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }}
    .header {{ background-color: #111827; padding: 32px 24px; text-align: center; }}
    .header h1 {{ color: #a3e635; margin: 0; font-size: 26px; font-weight: 700; letter-spacing: 0.5px; }}
    .content {{ padding: 32px 24px; color: #374151; line-height: 1.6; font-size: 16px; }}
    .content h2 {{ color: #111827; margin-top: 0; font-size: 20px; }}
    .badge {{ display: inline-block; background-color: #dcfce7; color: #166534; padding: 6px 14px; border-radius: 9999px; font-weight: 600; font-size: 14px; margin-bottom: 20px; }}
    .cta-button {{ display: inline-block; background-color: #a3e635; color: #111827; font-weight: 700; text-decoration: none; padding: 14px 28px; border-radius: 8px; margin-top: 24px; text-align: center; }}
    .footer {{ background-color: #f9fafb; padding: 20px 24px; text-align: center; font-size: 13px; color: #9ca3af; border-top: 1px solid #e5e7eb; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>OnlyGigz</h1>
    </div>
    <div class="content">
      <div class="badge">✓ Account Approved</div>
      <h2>Hello {user_name},</h2>
      <p>Great news! Your <strong>OnlyGigz</strong> account has been officially reviewed and approved by our team.</p>
      <p>You now have full access to log in, browse musician gigs, connect with venues and organizers, and manage your bookings seamlessly.</p>
      <p style="text-align: center;">
        <a href="https://onlygigz.com" class="cta-button">Log In to Your Account</a>
      </p>
      <p style="margin-top: 32px; font-size: 14px; color: #6b7280;">If you have any questions or need assistance getting started, feel free to reply directly to this email.</p>
    </div>
    <div class="footer">
      &copy; OnlyGigz. All rights reserved.
    </div>
  </div>
</body>
</html>"""

        plain_text = f"""Hello {user_name},

Great news! Your OnlyGigz account has been officially reviewed and approved by our team.

You now have full access to log in, browse musician gigs, connect with venues and organizers, and manage your bookings seamlessly.

Log in here: https://onlygigz.com

Best regards,
The OnlyGigz Team"""

        return EmailService.send_sendgrid_email(
            to_email=to_email,
            subject=subject,
            html_content=html_content,
            plain_text_content=plain_text,
            to_name=user_name
        )

    @staticmethod
    def send_account_denied_email(to_email: str, user_name: str = "Valued User") -> bool:
        """
        Sends the 'Account Review Status' rejection email notification via Twilio SendGrid.
        """
        subject = "OnlyGigz Account Review Status Update"
        
        html_content = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {{ font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f4f6f8; margin: 0; padding: 0; }}
    .container {{ max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }}
    .header {{ background-color: #111827; padding: 32px 24px; text-align: center; }}
    .header h1 {{ color: #ef4444; margin: 0; font-size: 26px; font-weight: 700; letter-spacing: 0.5px; }}
    .content {{ padding: 32px 24px; color: #374151; line-height: 1.6; font-size: 16px; }}
    .content h2 {{ color: #111827; margin-top: 0; font-size: 20px; }}
    .badge {{ display: inline-block; background-color: #fee2e2; color: #991b1b; padding: 6px 14px; border-radius: 9999px; font-weight: 600; font-size: 14px; margin-bottom: 20px; }}
    .cta-button {{ display: inline-block; background-color: #374151; color: #ffffff; font-weight: 600; text-decoration: none; padding: 12px 24px; border-radius: 8px; margin-top: 24px; text-align: center; }}
    .footer {{ background-color: #f9fafb; padding: 20px 24px; text-align: center; font-size: 13px; color: #9ca3af; border-top: 1px solid #e5e7eb; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>OnlyGigz</h1>
    </div>
    <div class="content">
      <div class="badge">Account Review Status</div>
      <h2>Hello {user_name},</h2>
      <p>Thank you for your interest in joining <strong>OnlyGigz</strong>.</p>
      <p>After reviewing your submitted profile details, our team was unable to approve your account application at this time.</p>
      <p>If you believe this was an error, or if you would like to provide additional details or verification to re-evaluate your application, please feel free to reply directly to this email or contact support at support@onlygigz.com.</p>
      <p style="text-align: center;">
        <a href="mailto:support@onlygigz.com" class="cta-button">Contact Support</a>
      </p>
    </div>
    <div class="footer">
      &copy; OnlyGigz. All rights reserved.
    </div>
  </div>
</body>
</html>"""

        plain_text = f"""Hello {user_name},

Thank you for your interest in joining OnlyGigz.

After reviewing your submitted profile details, our team was unable to approve your account application at this time.

If you believe this was an error, or if you would like to provide additional details or verification to re-evaluate your application, please reply directly to this email or contact support at support@onlygigz.com.

Best regards,
The OnlyGigz Team"""

        return EmailService.send_sendgrid_email(
            to_email=to_email,
            subject=subject,
            html_content=html_content,
            plain_text_content=plain_text,
            to_name=user_name
        )
