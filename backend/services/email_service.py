import os
import smtplib
from email.message import EmailMessage
from typing import Dict

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
