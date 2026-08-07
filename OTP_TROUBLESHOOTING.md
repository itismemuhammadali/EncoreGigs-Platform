# OTP Email Troubleshooting Guide

Use this guide to diagnose and fix OTP email issues.

---

## Symptom: Email Not Sending

### Check 1: Gmail Credentials

**Terminal output shows:**
```
❌ GMAIL AUTHENTICATION FAILED
Check your GMAIL_EMAIL and GMAIL_APP_PASSWORD in .env
```

**Solution:**

1. Verify credentials in `backend/.env`:
   ```bash
   cat backend/.env | grep GMAIL
   ```

2. Test Gmail connection:
   ```python
   import smtplib
   
   gmail = "your-email@gmail.com"
   password = "xxxx xxxx xxxx xxxx"
   
   try:
       server = smtplib.SMTP('smtp.gmail.com', 587)
       server.starttls()
       server.login(gmail, password)
       print("✅ Connection successful")
       server.quit()
   except smtplib.SMTPAuthenticationError:
       print("❌ Invalid email or password")
   except Exception as e:
       print(f"❌ Error: {e}")
   ```

3. If test fails, regenerate App Password:
   - Go to: https://myaccount.google.com/apppasswords
   - Select Mail + Windows Computer
   - Generate new password
   - Update `backend/.env`

### Check 2: Environment Variables Not Loaded

**Problem:** Backend can't find `GMAIL_EMAIL` or `GMAIL_APP_PASSWORD`

**Solution:**

```bash
# Verify .env file exists
ls -la backend/.env

# Check file is readable
cat backend/.env

# Verify format (no quotes)
# CORRECT:
GMAIL_EMAIL=admin@example.com
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx

# INCORRECT:
GMAIL_EMAIL="admin@example.com"
GMAIL_APP_PASSWORD="xxxx xxxx xxxx xxxx"
```

If .env is missing variables, the terminal shows:
```
⚠️  GMAIL CREDENTIALS NOT SET
[Logging instead of sending - configure .env]
```

### Check 3: Backend Not Running

**Problem:** Endpoint returns connection error

**Solution:**

```bash
# Check if backend is running
ps aux | grep uvicorn

# Start backend if not running
cd backend
python -m uvicorn main:app --reload

# Should show:
# INFO:     Uvicorn running on http://127.0.0.1:8000
```

### Check 4: SMTP Blocked

**Problem:** Error about "Less secure app access"

**Solution:**

Gmail has deprecated "Less secure app access". Use App Password instead:

1. Go to: https://myaccount.google.com
2. Verify 2-Step Verification is enabled
3. Go to App passwords
4. Generate 16-character password
5. Update `backend/.env`

---

## Symptom: Email Sent But Not Received

### Check 1: Email Going to Spam

**Solution:**

1. Check Gmail spam/promotions folder
2. Gmail is sending it, but filtering to spam folder
3. Add to whitelist:
   - Open email
   - Click three dots menu
   - Select "Add to contacts"

### Check 2: Wrong Recipient Email

**Problem:** Email sent to wrong address

**Diagnostic:**

```bash
# Check what email you're sending to
# Review the request:
curl -X POST http://localhost:8000/auth/send-email-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "michaelsmith02444@gmail.com",
    "uid": "user-123"
  }'

# Check terminal output shows correct email
# Example:
# To: michaelsmith02444@gmail.com
# From: admin@onlygigz.com
```

**Solution:**

- Verify recipient email is correct
- Check the email address in your request
- Use exact recipient address

### Check 3: Wrong Sender Email

**Problem:** Email shows as from unknown sender

**Diagnostic:**

```bash
# Check sender in backend/.env
grep GMAIL_EMAIL backend/.env
```

**Solution:**

- Sender must be the Gmail account with App Password
- If you changed Gmail accounts, regenerate App Password
- Update `GMAIL_EMAIL` in `.env`

---

## Symptom: OTP Verification Fails

### Check 1: Wrong OTP Code

**Error:**
```json
{"detail": "Invalid OTP code."}
```

**Solution:**

1. Copy OTP exactly from email (6 digits)
2. Don't add spaces or dashes
3. Use OTP within 10 minutes (before expiration)

### Check 2: OTP Expired

**Error:**
```json
{"detail": "OTP has expired. Please request a new one."}
```

**Solution:**

- OTP expires after 10 minutes
- Request a new OTP to get fresh code
- Expiration time is server-side controlled

### Check 3: No OTP Found

**Error:**
```json
{"detail": "No active OTP found for this email. Please request a new one."}
```

**Solution:**

1. You haven't requested OTP for this email
2. OTP was already used and deleted
3. Request new OTP first:
   ```bash
   curl -X POST http://localhost:8000/auth/send-email-otp \
     -H "Content-Type: application/json" \
     -d '{"email": "test@example.com", "uid": "user-123"}'
   ```

---

## Symptom: Terminal Shows No Error But Email Not Sent

### Check 1: Silent Failure

**Terminal output:**
```
✓ OTP saved to Firestore
📧 Sending email...
✅ EMAIL SENT SUCCESSFULLY
```

But email not received.

**Solution:**

1. SMTP might not be actually sending
2. Check Gmail account:
   - https://myaccount.google.com/security
   - Look for "2-Step Verification"
   - Check "App passwords" section

3. Test SMTP manually:
   ```python
   import smtplib
   from email.mime.multipart import MIMEMultipart
   from email.mime.text import MIMEText
   
   sender = "your-email@gmail.com"
   password = "xxxx xxxx xxxx xxxx"
   recipient = "michaelsmith02444@gmail.com"
   
   msg = MIMEMultipart()
   msg['From'] = sender
   msg['To'] = recipient
   msg['Subject'] = "Test Email"
   msg.attach(MIMEText("Test body", 'html'))
   
   try:
       server = smtplib.SMTP('smtp.gmail.com', 587)
       server.starttls()
       server.login(sender, password)
       server.send_message(msg)
       server.quit()
       print("✅ Test email sent successfully")
   except Exception as e:
       print(f"❌ Error: {e}")
   ```

---

## Symptom: Firebase Errors

### Check 1: Firestore Permission Denied

**Error:**
```
FirebaseError: [permission-denied] Missing or insufficient permissions
```

**Solution:**

Check Firestore rules in `firestore.rules`:

```
match /otps/{document=**} {
  allow read, write: if request.auth != null;
}
```

Or for testing:

```
match /otps/{document=**} {
  allow read, write;
}
```

Update rules:
```bash
firebase deploy --only firestore:rules
```

### Check 2: Firestore Not Connected

**Error:**
```
Connection refused / ECONNREFUSED
```

**Solution:**

1. Check if Firestore emulator is running:
   ```bash
   firebase emulators:start
   ```

2. Or connect to production Firebase:
   ```bash
   # Update backend/database.py to use production Firebase
   # instead of emulator
   ```

---

## Symptom: Cloud Function Issues

### Check 1: Function Not Deployed

**Error:**
```
404: Function not found
```

**Solution:**

```bash
# Check if functions are deployed
firebase functions:list

# Deploy functions
cd functions
npm install
firebase deploy --only functions

# Check logs
firebase functions:log
```

### Check 2: Function Environment Variables Not Set

**Error:**
```
TypeError: Cannot read property 'email' of undefined
```

**Solution:**

```bash
# Set environment variables
firebase functions:config:set gmail.email="your-email@gmail.com"
firebase functions:config:set gmail.password="xxxx xxxx xxxx xxxx"

# Deploy
firebase deploy --only functions
```

---

## Symptom: Tests Fail

### Test: Send OTP Returns Error

```bash
curl -X POST http://localhost:8000/auth/send-email-otp \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "uid": "user-123"}'

# Response: 500 Internal Server Error
```

**Diagnostic Steps:**

1. Check terminal for detailed error
2. Look for traceback in backend logs
3. Common causes:
   - Missing dependencies: `pip install -r requirements.txt`
   - Database connection: Firebase not initialized
   - Email config: Gmail credentials missing

### Test: Verify OTP Returns Error

```bash
curl -X POST http://localhost:8000/auth/verify-email-otp \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "otp": "123456"}'

# Response: 500 or 400 error
```

**Check Firestore:**

```bash
# View OTP documents
firebase firestore:get otps

# Delete old test OTPs
firebase firestore:delete otps/test@example.com --force
```

---

## Debug Mode

### Enable Verbose Logging

Edit `backend/routers/auth.py` and set:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Watch All Emails

```bash
# Monitor in real-time
firebase functions:log --follow

# Or check Firestore email_queue
firebase firestore:get email_queue
```

### Test Email Sending Script

```python
#!/usr/bin/env python3
import os
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from dotenv import load_dotenv

load_dotenv()

def test_email():
    gmail = os.getenv("GMAIL_EMAIL")
    password = os.getenv("GMAIL_APP_PASSWORD")
    
    print(f"Email: {gmail}")
    print(f"Password set: {'Yes' if password else 'No'}")
    
    if not gmail or not password:
        print("❌ Credentials not set in .env")
        return
    
    msg = MIMEMultipart()
    msg['From'] = gmail
    msg['To'] = "michaelsmith02444@gmail.com"
    msg['Subject'] = "OnlyGigz Test"
    msg.attach(MIMEText("<h1>Test OTP: 123456</h1>", 'html'))
    
    try:
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(gmail, password)
        server.send_message(msg)
        server.quit()
        print("✅ Email sent successfully")
    except smtplib.SMTPAuthenticationError:
        print("❌ Authentication failed")
        print("   Check GMAIL_EMAIL and GMAIL_APP_PASSWORD")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_email()
```

Run it:
```bash
cd backend
python test_email.py
```

---

## Quick Checklist

- [ ] Gmail App Password generated (https://myaccount.google.com/apppasswords)
- [ ] `backend/.env` has `GMAIL_EMAIL` and `GMAIL_APP_PASSWORD`
- [ ] `.env` file format is correct (no quotes)
- [ ] Backend running: `python -m uvicorn main:app --reload`
- [ ] Firestore configured and initialized
- [ ] Test SMTP connection succeeds
- [ ] Send OTP endpoint returns success
- [ ] Email received in inbox
- [ ] Verify OTP works with correct code
- [ ] Invalid OTP rejected
- [ ] Expired OTP rejected

---

## Still Not Working?

1. **Check all logs:**
   ```bash
   # Backend logs (terminal where you started backend)
   # Firebase logs
   firebase functions:log
   ```

2. **Test SMTP directly** using the script above

3. **Verify credentials** are exactly correct (copy-paste, not manually typed)

4. **Check Firebase rules** allow Firestore reads/writes

5. **Reset and try again:**
   ```bash
   # Regenerate App Password
   # Delete backend/.env entries
   # Create fresh entries
   # Restart backend
   ```

6. **Contact support with:**
   - Terminal output from backend
   - Firebase function logs
   - Error messages
   - What email you're trying to send to

---

**If you've checked everything and it's still not working, review:**
- CLOUD_FUNCTIONS_OTP_SETUP.md (detailed setup)
- TEST_OTP_EMAIL.md (testing procedures)
- QUICK_START_OTP_EMAIL.md (quick reference)
