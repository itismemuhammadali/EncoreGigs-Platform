# Firebase Cloud Functions - OTP Email Setup Guide

This guide explains how to deploy and configure Firebase Cloud Functions to send OTP verification emails for OnlyGigz.

## Overview

The Cloud Functions system provides two approaches for sending OTP emails:

1. **HTTP Callable Function** (`sendOtpEmail`) - Direct call from your Python backend
2. **Firestore Trigger** (`onOtpCreated`) - Automatic trigger when OTP is created in Firestore

## Prerequisites

1. Firebase project configured
2. Firebase CLI installed: `npm install -g firebase-tools`
3. Node.js 18+ installed
4. Gmail account with App Password enabled

## Step 1: Set Up Gmail App Password

To send emails via Gmail, you need to create an App Password (not your regular Gmail password):

### Instructions:

1. Go to [Google Account Security](https://myaccount.google.com/security)
2. Enable **2-Step Verification** (if not already enabled)
3. Once enabled, go back to Security settings
4. Scroll to "App passwords" and select it
5. Choose "Mail" and "Windows Computer" (or your device)
6. Google will generate a 16-character password
7. Copy this password - you'll use it below

**Important:** Store this password securely. Never commit it to version control.

## Step 2: Configure Environment Variables

Firebase Cloud Functions read from `.env.local` file in the `functions/` directory.

### Create `.env.local` file:

```bash
cd functions
```

Create a file named `.env.local` with:

```env
GMAIL_EMAIL=your-email@gmail.com
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
```

Replace:
- `your-email@gmail.com` with your Gmail address
- `xxxx xxxx xxxx xxxx` with the App Password from Step 1

### For Production (Firebase Project):

Set environment variables using Firebase CLI:

```bash
firebase functions:config:set gmail.email="your-email@gmail.com" gmail.password="xxxx xxxx xxxx xxxx"
```

Then reference them in code:

```javascript
const gmailEmail = functions.config().gmail.email;
const gmailPassword = functions.config().gmail.password;
```

## Step 3: Deploy Cloud Functions

### Install dependencies:

```bash
cd functions
npm install
```

### Deploy to Firebase:

```bash
# From project root
firebase deploy --only functions
```

Or deploy specific functions:

```bash
# Deploy only OTP email functions
firebase deploy --only functions:sendOtpEmail,functions:onOtpCreated
```

### Monitor deployment:

```bash
firebase functions:log --limit 50
```

## Step 4: Update Python Backend

The Python backend needs to call the Cloud Function. Here's the updated approach:

### Option A: Direct SMTP (Current Implementation)

The current `send_email_otp` endpoint in `/backend/routers/auth.py` uses direct SMTP:

```python
@router.post("/send-email-otp")
async def send_email_otp(request: SendEmailOTPRequest):
    # ... OTP generation code ...
    
    # Call Gmail SMTP directly
    _send_otp_email(to_email, otp_code)
    
    return {"message": "OTP sent successfully", "otp": otp_code}
```

**Requirements:**
- Add to `.env`:
  ```
  GMAIL_EMAIL=your-email@gmail.com
  GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
  ```

### Option B: Call Cloud Function from Backend

To call the Cloud Function from Python:

```python
import requests
import os

async def send_otp_via_cloud_function(email: str, otp_code: str, uid: str):
    """Call Firebase Cloud Function to send OTP email"""
    
    firebase_url = "https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/sendOtpEmail"
    
    payload = {
        "data": {
            "email": email,
            "otpCode": otp_code,
            "uid": uid
        }
    }
    
    try:
        response = requests.post(firebase_url, json=payload)
        result = response.json()
        
        if response.status_code == 200:
            print(f"✅ Cloud Function returned: {result}")
            return True
        else:
            print(f"❌ Cloud Function error: {result}")
            return False
    except Exception as e:
        print(f"❌ Error calling Cloud Function: {e}")
        return False
```

## Step 5: Test the Setup

### Test locally with Firebase Emulator:

```bash
# Start Firebase emulator
firebase emulators:start

# In another terminal, run backend
cd backend
python -m uvicorn main:app --reload
```

### Test email sending:

```bash
# Call the endpoint
curl -X POST http://localhost:8000/auth/send-email-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "michaelsmith02444@gmail.com",
    "uid": "test-user-123"
  }'
```

### Check function logs:

```bash
# View Cloud Function logs in real-time
firebase functions:log --limit 50 --follow

# Or view from Firebase Console
# Go to: Firebase Console > Functions > View Logs
```

## Step 6: Environment Variables Configuration

### For Local Development:

**Backend** (`.env` in `/backend`):
```env
GMAIL_EMAIL=your-email@gmail.com
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
```

**Cloud Functions** (`functions/.env.local`):
```env
GMAIL_EMAIL=your-email@gmail.com
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
```

### For Production:

Set environment variables in Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to Functions
4. Select the function
5. Click "Runtime settings"
6. Add environment variables:
   - `GMAIL_EMAIL`: your-email@gmail.com
   - `GMAIL_APP_PASSWORD`: xxxx xxxx xxxx xxxx

Or use CLI:

```bash
firebase functions:config:set gmail.email="your-email@gmail.com"
firebase functions:config:set gmail.password="xxxx xxxx xxxx xxxx"
firebase deploy --only functions
```

## Implementation Flow

### Current Flow (Direct SMTP):

1. User requests OTP → `/auth/send-email-otp`
2. Backend generates OTP (6 digits)
3. Backend saves to Firestore `otps/{email}`
4. Backend calls `_send_otp_email()` with SMTP
5. Email sent directly from backend
6. User receives email in inbox

### Alternative Flow (Firestore Trigger):

1. User requests OTP → `/auth/send-email-otp`
2. Backend generates OTP (6 digits)
3. Backend saves to Firestore `otps/{email}`
4. Cloud Function `onOtpCreated` is triggered
5. Cloud Function sends email via Gmail SMTP
6. Cloud Function updates status to `sent`
7. User receives email in inbox

## Troubleshooting

### Email not sending?

1. **Check credentials:**
   ```bash
   firebase functions:config:get
   ```

2. **Check logs:**
   ```bash
   firebase functions:log --limit 50
   ```

3. **Verify Gmail settings:**
   - 2-Step Verification is enabled
   - App Password is generated correctly
   - Gmail allows "Less secure app access" (if not using App Password)

4. **Test SMTP directly:**
   ```python
   import smtplib
   
   gmail = "your-email@gmail.com"
   password = "xxxx xxxx xxxx xxxx"
   
   try:
       server = smtplib.SMTP('smtp.gmail.com', 587)
       server.starttls()
       server.login(gmail, password)
       print("✅ Gmail SMTP connection successful")
       server.quit()
   except Exception as e:
       print(f"❌ Error: {e}")
   ```

### Function deployment fails?

1. Check Node.js version: `node --version` (should be 18+)
2. Check dependencies: `cd functions && npm install`
3. Check for syntax errors: `node -c functions/index.js`
4. Check Firebase auth: `firebase login`

### Email going to spam?

1. Add SPF record for Gmail
2. Configure DKIM
3. Add unsubscribe link (optional for transactional emails)
4. Use consistent sender name

## File Changes Summary

### Created/Modified Files:

1. **`functions/index.js`** - Updated with OTP email functions
2. **`functions/package.json`** - Added nodemailer dependency
3. **`functions/.env.local`** - Create this file with Gmail credentials
4. **`backend/routers/auth.py`** - Already has `_send_otp_email()` function
5. **`backend/.env`** - Add Gmail credentials

### Key Endpoints:

- **Send OTP:** `POST /auth/send-email-otp`
- **Verify OTP:** `POST /auth/verify-email-otp`
- **Cloud Function (HTTP):** `POST https://{region}-{project}.cloudfunctions.net/sendOtpEmail`

## Next Steps

1. ✅ Install dependencies: `cd functions && npm install`
2. ✅ Add Gmail credentials to `functions/.env.local`
3. ✅ Deploy functions: `firebase deploy --only functions`
4. ✅ Test OTP sending: Use the email endpoint
5. ✅ Check logs: `firebase functions:log`
6. ✅ Verify email receipt: Check your inbox

## Support

For issues or questions:

1. Check Firebase Console logs
2. Review function execution: `firebase functions:log`
3. Test SMTP connectivity separately
4. Verify Gmail App Password is correct
5. Check Firestore rules if using database trigger

---

**Last Updated:** 2025
**Status:** Ready for deployment
