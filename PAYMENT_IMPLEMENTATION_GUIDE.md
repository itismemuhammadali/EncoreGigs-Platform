# OnlyGigz Payment Implementation Guide (Escrow & Stripe Connect)

This guide provides the final, consolidated technical blueprint for the OnlyGigz payment system. It utilizes a **Fiverr-style Escrow model** where the platform holds funds in a single Stripe account until the Organizer releases them to the Musician.

## 0. Fundamental Constraints
- **NO UI CHANGES:** The visual design, layouts, colors, and existing buttons/text fields must remain 100% untouched.
- **DECOUPLED BACKEND:** All payment logic will reside in a new, specialized directory: `backend/payments/`.
- **SINGLE STRIPE ACCOUNT:** OnlyGigz platform account acts as the central intermediary (The Escrow).

---

## 1. Backend Architecture (`backend/payments/`)

We will create a dedicated module to handle all financial operations.

| File | Purpose |
| :--- | :--- |
| `backend/payments/service.py` | `StripeManager` class for direct interaction with the Stripe API (Transfers, Refunds, Intents). |
| `backend/payments/router.py` | FastAPI endpoints for frontend calls (e.g., `/payments/create-intent`, `/payments/release`). |
| `backend/payments/webhooks.py` | Handles incoming Stripe events to sync Firestore statuses automatically. |
| `backend/payments/models.py` | Pydantic models for request/response validation. |

---

## 2. Core Workflows

### **Workflow A: Musician Onboarding (Receiving Money)**
1.  **Trigger:** Musician clicks "Add Bank Account" in the existing UI.
2.  **Action:** App calls `POST /payments/musician/onboard`.
3.  **Backend:** Create Stripe Express Account -> Generate Onboarding Link.
4.  **UI:** Open link in browser. Upon completion, Stripe Webhook updates musician's `stripe_account_id` and `stripe_status` in Firestore.

### **Workflow B: Organizer Gig Funding (Escrow Deposit)**
1.  **Trigger:** Organizer clicks "Sign & Confirm" on the `ContractScreen`.
2.  **Action:** Backend `confirm_booking` is extended to call `StripeManager.deposit_to_escrow()`.
3.  **Stripe:** Charge the Organizer's saved card. Funds are captured to the **OnlyGigz Platform Balance**.
4.  **Status:** Firestore Booking status moves to `Payment in Escrow`.

### **Workflow C: The Release (Fiverr Model)**
1.  **Trigger:** Organizer clicks the existing "Release Payment" button in `BookingDetailsScreen`.
2.  **Action:** App calls `POST /payments/booking/{id}/release`.
3.  **Backend:**
    - Calculate: `Net Payment = Gross Amount - Platform Fee`.
    - Execute `stripe.Transfer.create()` from Platform -> Musician's Connected Account.
4.  **Status:** Firestore Booking status moves to `Payment Released`.

### **Workflow D: Admin Intervention (Refunds/Disputes)**
1.  **Trigger:** Admin clicks "Process Refund" in the Admin Portal.
2.  **Action:** Call `POST /payments/booking/{id}/refund`.
3.  **Backend:** Execute `stripe.Refund.create()` to return funds to the Organizer.

---

## 3. Database Schema Extensions
*Within existing `musicians`, `organizers`, and `bookings` collections:*

- **Users:**
    - `stripe_id`: (string) Customer ID for Organizers, Account ID for Musicians.
    - `stripe_status`: (string) `pending`, `active`, `restricted`.
- **Bookings:**
    - `charge_id`: (string) The Stripe ID for the initial deposit.
    - `transfer_id`: (string) The Stripe ID for the final payout.
    - `escrow_status`: (string) `held`, `released`, `refunded`.

---

## 4. Implementation Steps (Phased)

### **Phase 1: Foundation**
- Create `backend/payments/` folder.
- Setup `.env` with Stripe Keys.
- Register `payments_router` in `backend/main.py`.

### **Phase 2: Wiring the Apps (Data Only)**
- Connect Musician's "Add Bank" button.
- Connect Organizer's "Add Card" button (Tokenization).
- Integrate Stripe charge into the Hiring/Contract flow.

### **Phase 3: The Release Logic**
- Wire the "Release Payment" button.
- Implement the Admin Portal's Release/Refund buttons.

### **Phase 4: Sync & Polish**
- Implement Webhooks for real-time Firestore updates.
- Connect Admin Dashboard charts to live Stripe balance.

---

**FINAL WARNING:** 
Any modification to the UI components (margins, padding, text, font, colors, button placement) is strictly prohibited. Implementation is limited to the `onTap`/`onClick` handlers and backend logic.
