# OnlyGigz Web Frontend Integration & Backend Architecture Guide

> **Version:** 1.0.0  
> **Environment:** Staging / Production  
> **Target Audience:** Frontend Engineering Team  
> **Objective:** Connect an external or custom web frontend (Next.js / React / Vue) directly to the unified OnlyGigz backend ecosystem (FastAPI, Firebase, Firestore, Cloud Storage, and Stripe Connect).

---

## 1. System Architecture Overview

OnlyGigz uses a shared infrastructure where mobile clients (Musician & Organizer Flutter applications), admin portals, and external web clients connect to the **same database, authentication engine, and API services**. Any change made on web will immediately reflect in the mobile apps and vice versa.

```
                  ┌───────────────────────────────────────────────┐
                  │            OnlyGigz Web Frontend              │
                  │             (React / Next.js)                 │
                  └───────────────┬───────────────────────────────┘
                                  │
         ┌────────────────────────┴────────────────────────┬────────────────────────┐
         │                                                 │                        │
         ▼ (HTTPS / JSON REST)                             ▼ (Firebase Web SDK)     ▼ (Stripe.js)
┌───────────────────────────────┐               ┌───────────────────────┐ ┌───────────────────┐
│     FastAPI Backend API       │               │   Firebase Services   │ │  Stripe Connect   │
│  (https://api.onlygigz.app)   │               │   (onlygigz-33557)    │ │   (Elements /     │
├───────────────────────────────┤               ├───────────────────────┤ │   PaymentIntents) │
│ • Gig management & filters    │               │ • Firebase Auth       │ └───────────────────┘
│ • Booking & PDF contracts     │◄─────────────►│ • Firestore Database  │
│ • Escrow balance & payouts    │               │ • Cloud Storage       │
│ • Support & Notifications     │               └───────────────────────┘
└───────────────────────────────┘
```

---

## 2. API Base URLs & Interactive Documentation

The OnlyGigz backend is powered by FastAPI, featuring real-time interactive OpenAPI/Swagger schemas.

| Environment | Base URL | Interactive Docs (Swagger) | Alternative Docs (ReDoc) | Raw OpenAPI Schema |
| :--- | :--- | :--- | :--- | :--- |
| **Production** | `https://api.onlygigz.app` | [`/docs`](https://api.onlygigz.app/docs) | [`/redoc`](https://api.onlygigz.app/redoc) | [`/openapi.json`](https://api.onlygigz.app/openapi.json) |
| **Local / Dev** | `http://localhost:8000` | `http://localhost:8000/docs` | `http://localhost:8000/redoc` | `http://localhost:8000/openapi.json` |

---

## 3. Firebase Web Configuration & Console Setup

### Step 3.1: Register / Verify the Web App in Firebase Console
1. Open the [Firebase Console](https://console.firebase.google.com/) under the project: **`onlygigz-33557`**.
2. Go to **Project Settings** > **General** > scroll down to **Your apps**.
3. You can either use the existing registered Web App configuration below, or click **"Add App"** > select **Web (`</>`)**, enter an app nickname (e.g. `OnlyGigz Web`), and copy your specific config.

### Step 3.2: Firebase Web SDK Initialization
Install Firebase in your web project:
```bash
npm install firebase
# or
yarn add firebase
```

Initialize Firebase in your application (e.g., `src/lib/firebase.ts`):

```typescript
import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

export const firebaseConfig = {
  apiKey: "AIzaSyChynuewEnIYF376H9BDQr87BMtBmZmgjQ",
  authDomain: "onlygigz-33557.firebaseapp.com",
  projectId: "onlygigz-33557",
  storageBucket: "onlygigz-33557.firebasestorage.app",
  messagingSenderId: "941385767816",
  appId: "1:941385767816:web:cb0d9a49949215ad42383d",
};

export const app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
```

### Step 3.3: Authorized Domains for Web Authentication
Before logging in on your web client, ensure your web development and production domains are whitelisted:
1. In Firebase Console, go to **Authentication** > **Settings** > **Authorized domains**.
2. Add your domains:
   - `localhost`
   - `127.0.0.1`
   - Your staging/production URL (e.g., `app.onlygigz.app` or `your-project.vercel.app`).

### Step 3.4: Security Rules Considerations (Firestore & Storage)
The production security rules are already deployed in the project:

- **Firestore Rules (`firestore.rules`):**
  - All read/write operations require authenticated users (`request.auth != null`).
  - Musician profiles (`/musicians/{userId}`) and Organizer profiles (`/organizers/{userId}`) can only be updated by the account owner (`request.auth.uid == userId`).
  - Public terms and policies (`/policies/{policyId}`) allow unauthenticated reads.
  - Chats (`/chats/{chatId}/messages`) and Support Chats (`/support_chats/{userId}/messages`) require authentication.
- **Modifying / Testing Rules:**
  - If your web client requires public unauthenticated browsing for gig listings (e.g. a public landing page feed), you will need to update the `/gigs/{gigId}` rule in `firestore.rules` from `allow read: if isSignedIn();` to `allow read: if true;`.
- **Storage Rules (`storage.rules`):**
  - Requires `request.auth != null`.
  - Media path convention:
    - `/portfolios/{userId}/{fileName}`
    - `/profile_images/{userId}/{fileName}`
    - `/chat_attachments/{chatId}/{fileName}`
    - `/gigs/{gigId}/{fileName}`

---

## 4. Authentication & User Profile Flow

OnlyGigz categorizes users using **Role-Based Profiles**:
- `musician`: Solo artists, bands, DJs, instrumentalists.
- `organizer`: Venues, event planners, individual clients booking talent.
- `admin`: Platform administrative staff.

### 4.1 Authentication Methods Supported
- **Email & Password:** Standard Firebase Auth (`signInWithEmailAndPassword`, `createUserWithEmailAndPassword`).
- **Google Sign-In:** `signInWithPopup(auth, new GoogleAuthProvider())`.
- **Phone / SMS 2FA:** Supported via Firebase Phone Auth and `/auth/2fa/*` endpoints.

### 4.2 Key Auth API Endpoints

| Method | Endpoint | Description | Payload Example |
| :--- | :--- | :--- | :--- |
| `POST` | `/auth/signin` | Sign in verification & role retrieval | `{"email": "user@example.com", "password": "..."}` |
| `POST` | `/auth/signup` | Organizer registration | `{"email": "org@example.com", "password": "...", "fullName": "Jane Doe", "organizationName": "Club Luna"}` |
| `POST` | `/auth/signup/musician` | Musician registration | `{"email": "musician@...", "password": "...", "fullName": "Alex Rivera", "stageName": "A-R", "genre": "Jazz", "hourlyRate": 150.0}` |
| `GET` | `/auth/profile/{uid}` | Fetch full user profile from Firestore | Returns musician/organizer profile document |
| `POST` | `/auth/profile/update` | Update general user profile | `{"uid": "...", "fullName": "...", "bio": "..."}` |
| `POST` | `/auth/send-email-otp` | Trigger verification code to user email | `{"email": "user@example.com"}` |
| `POST` | `/auth/verify-email-otp`| Verify email code | `{"email": "user@example.com", "otp": "123456"}` |

---

## 5. Core Backend Modules & Endpoint Reference

### 5.1 Gigs (`/gigs`)
- **`GET /gigs/list`**
  - Query parameters:
    - `status` (`open`, `booked`, `completed`, `cancelled`)
    - `organizer_id` (Filter gigs created by a specific organizer)
    - `search_query` (Text search by title, genre, venue)
- **`GET /gigs/{gig_id}`** — Retrieve individual gig details.
- **`POST /gigs/create`** — Create a new gig listing (organizer).
- **`POST /gigs/apply`** — Musician submits an application with quote and message.
- **`GET /gigs/applications/list`** — List applications (filtered by `gig_id` or `musician_id`).
- **`PATCH /gigs/{gig_id}/status`** — Update gig status (`open`, `booked`, etc.).
- **`DELETE /gigs/{gig_id}`** — Remove a gig listing.

### 5.2 Bookings & Contracts (`/bookings`)
- **`POST /bookings/confirm`** — Confirm an accepted application into an active booking.
- **`GET /bookings/list`** — List user bookings (`musician_id` or `organizer_id`).
- **`GET /bookings/{booking_id}`** — Fetch booking details, escrow status, and contract.
- **`POST /bookings/{booking_id}/musician-sign`** — Musician attaches digital signature URL.
- **`GET /bookings/{booking_id}/contract/pdf`** — Generates and downloads official OnlyGigz legal contract PDF.

### 5.3 Real-Time Chat & Messaging (`/chat`)
Chats can be listened to in real-time via the Firebase Client SDK or sent via FastAPI:
- **FastAPI Endpoints:**
  - `POST /chat/get-or-create` — Initialize or fetch a conversation between musician and organizer.
  - `POST /chat/send-message` — Send text message.
  - `GET /chat/unread-count/{user_id}` — Get aggregate unread count.
  - `POST /chat/mark-read/{chat_id}/{user_id}` — Mark conversation as read.
- **Direct Firestore Real-time Listener:**
  - Collection path: `chats/{chatId}/messages` (Ordered by `timestamp` ascending).

### 5.4 Reviews & Ratings (`/reviews`)
- **`GET /reviews/list`** — Get recent reviews across the platform.
- **`GET /reviews/stats`** — Average ratings and breakdown.
- **`POST /reviews/{review_id}/flag`** — Flag inappropriate reviews for admin moderation.

### 5.5 Support & Help Desk (`/support`)
- **`GET /support/chats/{user_id}/messages`** — Fetch messages between user and support.
- **`POST /support/chats/{user_id}/messages`** — Send support ticket message.

### 5.6 Notifications (`/notifications`)
- **`GET /notifications/user/{user_id}`** — Fetch in-app notifications.
- **`GET /notifications/user/{user_id}/unread-count`** — Unread badge counter.
- **`PATCH /notifications/{notification_id}/read`** — Mark notification as acknowledged.

---

## 6. Stripe & Escrow Payments Flow (Web Implementation)

OnlyGigz uses Stripe Connect with an **Escrow Architecture**:
1. Organizer deposits booking funds into Escrow.
2. Funds are safely held on Stripe until gig performance.
3. Upon gig completion, funds are released to the Musician's connected Stripe Express account (minus platform service fees).

### 6.1 Stripe Keys
- **Publishable Key (Test):**
  `pk_test_51TWa16C4PTfB0I2XPl7KWaEgeyQOWAKXvicPoQoF3GxAmIFBYMeKI2Y9AsRNvdny7dzVJ7Inj9W15zVP7CfyKDPF003AgOz7G8`

### 6.2 Organizer Payment & Card Saving on Web
Unlike the mobile app which uses native `flutter_stripe` bottom sheets, the web client should use `@stripe/stripe-js` and `@stripe/react-stripe-js` with **Stripe Elements**:

1. **Create Customer:** Call `POST /payments/organizer/customer` with `{ "organizerId": uid }`.
2. **Setup Intent:** Call `POST /payments/organizer/setup-intent` with `{ "organizerId": uid }`.
   - The backend returns `{ "clientSecret": "seti_..._secret_...", "customerId": "cus_..." }`.
3. **Mount PaymentElement:** Render Stripe `PaymentElement` on your checkout/wallet page.
4. **Confirm Card:** Run `stripe.confirmSetup({ elements, confirmParams: { return_url: window.location.href } })`.
5. **Save to OnlyGigz Database:** Call `POST /payments/organizer/save-payment-method` with `{ "organizerId": uid, "paymentMethodId": setupIntent.payment_method }`.
6. **Escrow Deposit:** When confirming a gig, call `POST /payments/booking/{booking_id}/deposit` with `{ "organizerId": uid, "amount": 500.0 }`.

### 6.3 Musician Payout Onboarding (Stripe Express)
1. Call `POST /payments/musician/onboard` with:
   ```json
   {
     "musicianId": "USER_UID",
     "refreshUrl": "https://your-web-app.com/wallet?refresh=true",
     "returnUrl": "https://your-web-app.com/wallet?success=true"
   }
   ```
2. The endpoint creates a Stripe Express Connected Account and returns an `onboardingUrl`.
3. Redirect the musician to `onboardingUrl` for official KYC/payout bank setup.

---

## 7. CORS & Domain Whitelisting

The backend has CORS enabled in `backend/main.py`. The currently whitelisted origins are:
- `https://admin.onlygigz.app`
- `https://onlygigz.app`
- `https://www.onlygigz.app`
- `http://localhost:3000`
- `http://localhost:8000`
- `http://127.0.0.1:3000`
- Regex pattern: `https://.*onlygigz\.app`

> **Note:** If you host your web frontend on a different staging domain (such as `vercel.app`, `netlify.app`, or a custom subdomain), please provide your exact origin domain so we can add it to the FastAPI CORS origins list.

---

## 8. Summary Checklist for Web Developer

- [ ] Install `firebase` and initialize using the config in **Section 3.2**.
- [ ] Add your local & production web domains to **Firebase Authorized Domains** in the console.
- [ ] Set your API client base URL to `https://api.onlygigz.app`.
- [ ] Explore all endpoint schemas and test requests via [`https://api.onlygigz.app/docs`](https://api.onlygigz.app/docs).
- [ ] Set up `@stripe/stripe-js` with the Stripe publishable key in **Section 6.1**.
- [ ] Notify the backend team of any new web deployment URLs to whitelist in CORS.
