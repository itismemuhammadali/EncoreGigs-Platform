# Quick Start: OTP Email Setup (15 minutes)

Get OTP emails working in 3 simple steps.

## Step 1: Generate Gmail App Password (5 min)

1. Go to: https://myaccount.google.com/apppasswords
2. Select "Mail" and "Windows Computer"
3. Google generates a 16-character password (example: `xxxx xxxx xxxx xxxx`)
4. **Copy this password** - you'll use it next

## Step 2: Configure Environment (3 min)

### Backend Configuration

Edit `backend/.env`:

```env
GMAIL_EMAIL=your-email@gmail.com
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
```

**Example:**
```env
GMAIL_EMAIL=admin@onlygigz.com
GMAIL_APP_PASSWORD=abcd efgh ijkl mnop
```

### Cloud Functions Configuration (Optional)

Create `functions/.env.local`:

```env
GMAIL_EMAIL=your-email@gmail.com
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
```

## Step 3: Test It (5 min)

### Start Backend

```bash
cd backend
python -m uvicorn main:app --reload
```

### Send OTP Email

```bash
curl -X POST http://localhost:8000/auth/send-email-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "michaelsmith02444@gmail.com",
    "uid": "user-123"
  }'
```

**You should see in terminal:**
```
✅ EMAIL SENT SUCCESSFULLY
To: michaelsmith02444@gmail.com
From: your-email@gmail.com
OTP: 512345
```

### Receive Email

Check your inbox at michaelsmith02444@gmail.com. You should see:
- From: Your configured Gmail
- Subject: "OnlyGigz - Your Verification Code"
- Content: 6-digit OTP in large format
- Branding: OnlyGigz logo and "Where Music Meets Opportunity"

### Verify the OTP

```bash
# Replace 512345 with the OTP you received
curl -X POST http://localhost:8000/auth/verify-email-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "michaelsmith02444@gmail.com",
    "otp": "512345"
  }'
```

**Expected response:**
```json
{
  "message": "OTP verified successfully",
  "uid": "user-123"
}
```

---

## ✅ Done!

You now have working OTP email authentication.

### What's Happening:

1. **User requests OTP** → Backend generates 6-digit code
2. **Code is saved** → Firestore stores with 10-minute expiry
3. **Email is sent** → Gmail SMTP sends HTML email
4. **User verifies** → Backend checks OTP validity
5. **Code is deleted** → After verification, OTP is cleared

---

## Common Issues

### Email Not Sending?

```
❌ GMAIL AUTHENTICATION FAILED
Check your GMAIL_EMAIL and GMAIL_APP_PASSWORD in .env
```

**Solution:** Generate a new App Password (https://myaccount.google.com/apppasswords)

### OTP Not Received?

1. Check spam/promotions folder
2. Verify sender email is correct in `.env`
3. Check terminal logs for errors

### Verification Fails?

- Copy the exact OTP from the email (6 digits)
- Use correct email and OTP in verify request
- OTP expires after 10 minutes

---

## File Changes Summary

### Created:
- `functions/index.js` - Cloud Functions for email
- `functions/.env.local` - Function environment (create with your credentials)
- `CLOUD_FUNCTIONS_OTP_SETUP.md` - Detailed setup guide
- `TEST_OTP_EMAIL.md` - Comprehensive testing guide

### Updated:
- `backend/.env` - Add GMAIL credentials
- `backend/routers/auth.py` - Enhanced email function
- `functions/package.json` - Added nodemailer

### API Endpoints:
- **Send OTP:** `POST /auth/send-email-otp`
- **Verify OTP:** `POST /auth/verify-email-otp`

---

## Next Steps (Optional)

### Deploy to Production
```bash
firebase deploy --only functions
```

### Set Up Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

### Monitor Emails
```bash
firebase functions:log --follow
```

---

## Get More Help

- Full setup guide: `CLOUD_FUNCTIONS_OTP_SETUP.md`
- Testing guide: `TEST_OTP_EMAIL.md`
- Gmail App Password help: https://myaccount.google.com/apppasswords
- Firebase docs: https://firebase.google.com/docs/functions

---

**Status:** ✅ Ready to use
**Last Updated:** 2025
