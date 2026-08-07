# Testing OTP Email System

This guide explains how to test the OTP email system end-to-end.

## Quick Test (5 minutes)

### 1. Start the Backend

```bash
# Navigate to backend directory
cd backend

# Ensure .env has Gmail credentials
# GMAIL_EMAIL=your-email@gmail.com
# GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx

# Start the backend (with virtual environment)
python -m uvicorn main:app --reload
```

The backend should start on `http://localhost:8000`

### 2. Test OTP Generation & Email Sending

Using curl:

```bash
curl -X POST http://localhost:8000/auth/send-email-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "michaelsmith02444@gmail.com",
    "uid": "test-user-123"
  }'
```

Expected response:

```json
{
  "message": "OTP sent successfully",
  "otp": "511874",
  "email": "michaelsmith02444@gmail.com",
  "expiresIn": 600
}
```

### 3. Check Email

1. Open Gmail: https://mail.google.com
2. Check the inbox for the email from your configured Gmail account
3. The email should show:
   - OnlyGigz branding
   - 6-digit OTP code clearly displayed
   - Expiration time (10 minutes)
   - "Where Music Meets Opportunity" tagline

### 4. Test OTP Verification

```bash
# Using the OTP from step 2 (e.g., 511874)
curl -X POST http://localhost:8000/auth/verify-email-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "michaelsmith02444@gmail.com",
    "otp": "511874"
  }'
```

Expected response:

```json
{
  "message": "OTP verified successfully",
  "uid": "test-user-123"
}
```

---

## Complete Test Scenario

### Prerequisites

Before testing, ensure:

1. **Gmail Account Setup:**
   ```bash
   # Go to: https://myaccount.google.com/apppasswords
   # Generate App Password
   # Copy the 16-character password
   ```

2. **Environment Configuration:**
   
   Create or update `backend/.env`:
   ```env
   GMAIL_EMAIL=your-email@gmail.com
   GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
   # ... other env vars
   ```

3. **Dependencies Installed:**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

### Test Flow

#### Test 1: Send OTP Email

**Request:**
```bash
POST http://localhost:8000/auth/send-email-otp

{
  "email": "michaelsmith02444@gmail.com",
  "uid": "user-001"
}
```

**Expected Output (Terminal):**
```
==============================================================
🔷 SEND EMAIL OTP ENDPOINT CALLED
==============================================================
Email: michaelsmith02444@gmail.com
UID: user-001
Generated OTP: 123456
✓ OTP saved to Firestore
📧 Sending email...
============================================================
✅ EMAIL SENT SUCCESSFULLY
============================================================
To: michaelsmith02444@gmail.com
From: your-email@gmail.com
UID: user-001
OTP: 123456
============================================================
```

**Expected Response (JSON):**
```json
{
  "message": "OTP sent successfully",
  "otp": "123456",
  "email": "michaelsmith02444@gmail.com",
  "expiresIn": 600
}
```

**Email Received:**
- Subject: `OnlyGigz - Your Verification Code`
- From: Your configured Gmail
- Contains: 6-digit OTP in large format with OnlyGigz branding

---

#### Test 2: Verify OTP

**Request:**
```bash
POST http://localhost:8000/auth/verify-email-otp

{
  "email": "michaelsmith02444@gmail.com",
  "otp": "123456"
}
```

**Expected Response:**
```json
{
  "message": "OTP verified successfully",
  "uid": "user-001"
}
```

**Firestore Result:**
- The OTP document is deleted after successful verification
- The OTP cannot be reused

---

#### Test 3: OTP Expiration

**Setup:**
```bash
# Send OTP
curl -X POST http://localhost:8000/auth/send-email-otp \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "uid": "user-002"}'

# Wait 10+ minutes for OTP to expire
sleep 600

# Try to verify the expired OTP
curl -X POST http://localhost:8000/auth/verify-email-otp \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "otp": "123456"}'
```

**Expected Response:**
```json
{
  "detail": "OTP has expired. Please request a new one."
}
```

---

#### Test 4: Invalid OTP

**Request:**
```bash
curl -X POST http://localhost:8000/auth/verify-email-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "michaelsmith02444@gmail.com",
    "otp": "000000"
  }'
```

**Expected Response:**
```json
{
  "detail": "Invalid OTP code."
}
```

---

#### Test 5: No Active OTP

**Request:**
```bash
curl -X POST http://localhost:8000/auth/verify-email-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "never-requested@example.com",
    "otp": "123456"
  }'
```

**Expected Response:**
```json
{
  "detail": "No active OTP found for this email. Please request a new one."
}
```

---

## Troubleshooting Tests

### Issue: Email Not Sending

**Check 1: Verify Gmail Credentials**
```bash
# Test SMTP connection
python3 << 'EOF'
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
EOF
```

**Check 2: Verify .env is Loaded**
```bash
# Add this to test_email.py
import os
from dotenv import load_dotenv

load_dotenv()
print(f"GMAIL_EMAIL: {os.getenv('GMAIL_EMAIL')}")
print(f"GMAIL_APP_PASSWORD: {'*' * len(os.getenv('GMAIL_APP_PASSWORD', ''))}")
```

**Check 3: Check Backend Logs**
```bash
# Look for error messages in terminal
# Common errors:
# - "GMAIL AUTHENTICATION FAILED" → Wrong password
# - "SMTP ERROR" → Network or server issue
# - "ERROR SENDING EMAIL" → Unknown issue
```

### Issue: Email Going to Spam

1. Check spam folder in Gmail
2. Add whitelist rule if needed
3. Verify sender domain has SPF/DKIM records

### Issue: OTP Not Saving in Firestore

```bash
# Check Firestore rules allow writes
firebase firestore:indexes

# Check Firestore logs
firebase functions:log
```

---

## Automated Testing

### Create test script: `test_otp.py`

```python
#!/usr/bin/env python3

import requests
import time
import json
import os
from dotenv import load_dotenv

load_dotenv()

BASE_URL = "http://localhost:8000/auth"
TEST_EMAIL = "michaelsmith02444@gmail.com"

def test_send_otp():
    """Test sending OTP"""
    print("\n📧 Test 1: Send OTP")
    print("-" * 50)
    
    response = requests.post(
        f"{BASE_URL}/send-email-otp",
        json={
            "email": TEST_EMAIL,
            "uid": "test-user-001"
        }
    )
    
    assert response.status_code == 200, f"Failed: {response.text}"
    data = response.json()
    assert "otp" in data, "No OTP in response"
    
    print(f"✅ OTP sent: {data['otp']}")
    return data['otp']

def test_verify_otp(otp):
    """Test verifying OTP"""
    print("\n✅ Test 2: Verify OTP")
    print("-" * 50)
    
    response = requests.post(
        f"{BASE_URL}/verify-email-otp",
        json={
            "email": TEST_EMAIL,
            "otp": otp
        }
    )
    
    assert response.status_code == 200, f"Failed: {response.text}"
    data = response.json()
    assert data["message"] == "OTP verified successfully"
    
    print(f"✅ OTP verified for UID: {data['uid']}")

def test_invalid_otp():
    """Test invalid OTP"""
    print("\n❌ Test 3: Invalid OTP")
    print("-" * 50)
    
    response = requests.post(
        f"{BASE_URL}/verify-email-otp",
        json={
            "email": TEST_EMAIL,
            "otp": "000000"
        }
    )
    
    assert response.status_code != 200 or "error" in response.json()
    print(f"✅ Correctly rejected invalid OTP")

if __name__ == "__main__":
    print("\n🚀 OnlyGigz OTP Email Testing")
    print("=" * 50)
    
    try:
        otp = test_send_otp()
        test_verify_otp(otp)
        test_invalid_otp()
        
        print("\n" + "=" * 50)
        print("✅ All tests passed!")
        print("=" * 50)
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        exit(1)
```

Run the test:
```bash
python test_otp.py
```

---

## Cloud Functions Testing

### Test Cloud Function Deployment

```bash
# Check if deployed
firebase functions:list

# View logs
firebase functions:log --limit 50

# Monitor in real-time
firebase functions:log --follow
```

### Test Cloud Function Trigger

```bash
# When OTP is created in Firestore, the function should:
# 1. Read OTP document
# 2. Send email via Gmail SMTP
# 3. Update status to 'sent'
# 4. Log the operation

# Check Firestore:
# firebase firestore:delete otps/michaelsmith02444@gmail.com --force
```

---

## Integration Test Checklist

- [ ] Gmail app password generated
- [ ] Backend .env configured
- [ ] Backend running on localhost:8000
- [ ] Send OTP endpoint returns 200 OK
- [ ] Email received in inbox within 5 seconds
- [ ] Email has correct formatting
- [ ] Email has OnlyGigz branding
- [ ] OTP code is visible in email
- [ ] Verify OTP endpoint validates correctly
- [ ] Invalid OTP is rejected
- [ ] Expired OTP is rejected
- [ ] OTP deleted after verification

---

## Production Testing

Before deploying to production:

1. **Test with Real Email:**
   ```bash
   curl -X POST https://api.onlygigz.com/auth/send-email-otp \
     -H "Content-Type: application/json" \
     -d '{"email": "your-email@example.com", "uid": "user-id"}'
   ```

2. **Check Firebase Console:**
   - Go to: https://console.firebase.google.com
   - Select project
   - Check Functions logs
   - Check Firestore email_queue collection

3. **Monitor Errors:**
   - Set up alerts for failed emails
   - Monitor SMTP errors
   - Track email delivery rates

---

## Support

For issues:
1. Check backend logs: `tail -f /path/to/backend.log`
2. Check Firebase logs: `firebase functions:log`
3. Test SMTP manually
4. Review `CLOUD_FUNCTIONS_OTP_SETUP.md`
