import os
import smtplib
from email.message import EmailMessage
from typing import Any, Dict, Optional

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
                db: Any = firestore.client()
                doc: Any = db.collection("system_config").document("email").get()
                if getattr(doc, "exists", False):
                    data: Dict[str, Any] = (doc.to_dict() if hasattr(doc, "to_dict") else {}) or {}
                    api_key = data.get("sendgrid_api_key") or data.get("sendgridApiKey") or data.get("api_key")
                
                if not api_key:
                    doc2: Any = db.collection("system_config").document("sendgrid").get()
                    if getattr(doc2, "exists", False):
                        data2: Dict[str, Any] = (doc2.to_dict() if hasattr(doc2, "to_dict") else {}) or {}
                        api_key = data2.get("sendgrid_api_key") or data2.get("sendgridApiKey") or data2.get("api_key")
            except Exception as e:
                print(f"EmailService: Firestore SendGrid key lookup note: {e}")

        return {
            "api_key": api_key,
            "from_email": os.getenv("SENDGRID_FROM_EMAIL") or os.getenv("SMTP_FROM_EMAIL", "notifications@onlygigz.app"),
            "from_name": os.getenv("SENDGRID_FROM_NAME", "OnlyGigz Team")
        }

    @staticmethod
    def _get_logo_attachment():
        """Reads OnlyGigz logo from public directory and prepares inline SendGrid attachment."""
        try:
            import base64
            current_file = os.path.abspath(__file__)
            root_dir = os.path.dirname(os.path.dirname(os.path.dirname(current_file)))
            logo_path = os.path.join(root_dir, "web", "admin_portal", "public", "logo.png")
            if not os.path.exists(logo_path):
                logo_path = os.path.join(root_dir, "public", "logo.png")
            if os.path.exists(logo_path):
                with open(logo_path, "rb") as f:
                    encoded = base64.b64encode(f.read()).decode("utf-8")
                    return {
                        "content": encoded,
                        "type": "image/png",
                        "filename": "logo.png",
                        "disposition": "inline",
                        "content_id": "onlygigz-logo"
                    }
        except Exception as e:
            print(f"EmailService: Error loading logo attachment: {e}")
        return None

    @staticmethod
    def send_sendgrid_email(
        to_email: str,
        subject: str,
        html_content: str,
        plain_text_content: Optional[str] = None,
        to_name: Optional[str] = None,
        attachments: Optional[list] = None
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

        payload: Dict[str, Any] = {
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

        if attachments:
            payload["attachments"] = attachments

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
        Sends the branded 'Your Account Has Been Approved' email notification via Twilio SendGrid.
        """
        subject = "Your OnlyGigz Account Has Been Approved! 🎉"
        logo_attachment = EmailService._get_logo_attachment()
        attachments = [logo_attachment] if logo_attachment else []
        
        html_content = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {{ font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #0A0A0F; margin: 0; padding: 0; }}
    .container {{ max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 8px 30px rgba(0,0,0,0.25); }}
    .header {{ background-color: #0A0A0F; padding: 36px 24px; text-align: center; border-bottom: 2px solid #A1F301; }}
    .header img {{ height: 48px; max-width: 180px; object-fit: contain; display: block; margin: 0 auto; }}
    .header-tag {{ color: #A1F301; margin-top: 10px; font-size: 13px; font-weight: 700; letter-spacing: 1.5px; text-transform: uppercase; }}
    .content {{ padding: 36px 28px; color: #374151; line-height: 1.6; font-size: 16px; }}
    .content h2 {{ color: #111827; margin-top: 0; font-size: 22px; font-weight: 700; }}
    .badge {{ display: inline-block; background-color: #dcfce7; color: #15803d; padding: 6px 14px; border-radius: 9999px; font-weight: 700; font-size: 13px; margin-bottom: 20px; text-transform: uppercase; letter-spacing: 0.5px; }}
    .cta-button {{ display: inline-block; background-color: #A1F301; color: #0A0A0F; font-weight: 800; text-decoration: none; padding: 14px 32px; border-radius: 10px; margin-top: 24px; text-align: center; font-size: 16px; box-shadow: 0 4px 14px rgba(161, 243, 1, 0.4); }}
    .footer {{ background-color: #f9fafb; padding: 24px; text-align: center; font-size: 13px; color: #9ca3af; border-top: 1px solid #e5e7eb; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <img src="cid:onlygigz-logo" alt="OnlyGigz Logo" onerror="this.style.display='none'" />
      <div class="header-tag">OnlyGigz Platform</div>
    </div>
    <div class="content">
      <div class="badge">✓ Account Approved</div>
      <h2>Hello {user_name},</h2>
      <p>Great news! Your <strong>OnlyGigz</strong> account application has been reviewed and officially approved by our team.</p>
      <p>You now have full access to explore gigs, connect with venues and organizers, and manage bookings and payments securely through the platform.</p>
      <p style="text-align: center; margin: 32px 0;">
        <a href="https://onlygigz.app" class="cta-button">Log In to Your Account</a>
      </p>
      <p style="margin-top: 32px; font-size: 14px; color: #6b7280; border-top: 1px solid #f3f4f6; padding-top: 16px;">
        If you have any questions or need assistance getting started, feel free to reply directly to this email.
      </p>
    </div>
    <div class="footer">
      &copy; OnlyGigz. All rights reserved. &bull; <a href="https://onlygigz.app" style="color: #6b7280; text-decoration: none;">onlygigz.app</a>
    </div>
  </div>
</body>
</html>"""

        plain_text = f"""Hello {user_name},

Great news! Your OnlyGigz account has been officially reviewed and approved by our team.

You now have full access to log in, browse musician gigs, connect with venues and organizers, and manage your bookings seamlessly.

Log in here: https://onlygigz.app

Best regards,
The OnlyGigz Team"""

        return EmailService.send_sendgrid_email(
            to_email=to_email,
            subject=subject,
            html_content=html_content,
            plain_text_content=plain_text,
            to_name=user_name,
            attachments=attachments
        )

    @staticmethod
    def send_account_denied_email(to_email: str, user_name: str = "Valued User") -> bool:
        """
        Sends the branded 'Account Review Status' rejection email notification via Twilio SendGrid.
        """
        subject = "OnlyGigz Account Review Status Update"
        logo_attachment = EmailService._get_logo_attachment()
        attachments = [logo_attachment] if logo_attachment else []
        support_email = os.getenv("SUPPORT_EMAIL", "support@onlygigz.app")
        
        html_content = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {{ font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #0A0A0F; margin: 0; padding: 0; }}
    .container {{ max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 8px 30px rgba(0,0,0,0.25); }}
    .header {{ background-color: #0A0A0F; padding: 36px 24px; text-align: center; border-bottom: 2px solid #ef4444; }}
    .header img {{ height: 48px; max-width: 180px; object-fit: contain; display: block; margin: 0 auto; }}
    .header-tag {{ color: #ffffff; margin-top: 10px; font-size: 13px; font-weight: 700; letter-spacing: 1.5px; text-transform: uppercase; }}
    .content {{ padding: 36px 28px; color: #374151; line-height: 1.6; font-size: 16px; }}
    .content h2 {{ color: #111827; margin-top: 0; font-size: 22px; font-weight: 700; }}
    .badge {{ display: inline-block; background-color: #fee2e2; color: #991b1b; padding: 6px 14px; border-radius: 9999px; font-weight: 700; font-size: 13px; margin-bottom: 20px; text-transform: uppercase; letter-spacing: 0.5px; }}
    .cta-button {{ display: inline-block; background-color: #1f2937; color: #ffffff; font-weight: 700; text-decoration: none; padding: 14px 28px; border-radius: 10px; margin-top: 24px; text-align: center; font-size: 15px; }}
    .footer {{ background-color: #f9fafb; padding: 24px; text-align: center; font-size: 13px; color: #9ca3af; border-top: 1px solid #e5e7eb; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <img src="cid:onlygigz-logo" alt="OnlyGigz Logo" onerror="this.style.display='none'" />
      <div class="header-tag">OnlyGigz Platform</div>
    </div>
    <div class="content">
      <div class="badge">Account Review Status</div>
      <h2>Hello {user_name},</h2>
      <p>Thank you for your interest in joining <strong>OnlyGigz</strong>.</p>
      <p>After reviewing your submitted profile details, our team was unable to approve your account application at this time.</p>
      <p>If you believe this was an error, or if you would like to provide additional details or verification to re-evaluate your application, please feel free to reply directly to this email or contact support at <a href="mailto:{support_email}" style="color: #4f46e5; text-decoration: underline;">{support_email}</a>.</p>
      <p style="text-align: center; margin: 32px 0;">
        <a href="mailto:{support_email}" class="cta-button">Contact Support Team</a>
      </p>
    </div>
    <div class="footer">
      &copy; OnlyGigz. All rights reserved. &bull; <a href="https://onlygigz.app" style="color: #6b7280; text-decoration: none;">onlygigz.app</a>
    </div>
  </div>
</body>
</html>"""

        plain_text = f"""Hello {user_name},

Thank you for your interest in joining OnlyGigz.

After reviewing your submitted profile details, our team was unable to approve your account application at this time.

If you believe this was an error, or if you would like to provide additional details or verification to re-evaluate your application, please reply directly to this email or contact support at {support_email}.

Best regards,
The OnlyGigz Team"""

        return EmailService.send_sendgrid_email(
            to_email=to_email,
            subject=subject,
            html_content=html_content,
            plain_text_content=plain_text,
            to_name=user_name,
            attachments=attachments
        )
