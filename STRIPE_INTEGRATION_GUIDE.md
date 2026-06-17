# OnlyGigz Stripe Connect Escrow Integration Guide (Fiverr Model)

This document outlines the implementation for the OnlyGigz Escrow system, where the Organizer pays upfront and releases funds to the Musician upon completion.

## 1. Roles & Flow
- **Organizer (Payer):** Deposits 100% of the gig fee into OnlyGigz Platform Escrow.
- **Platform (Escrow):** Holds funds securely in the platform's Stripe balance.
- **Musician (Payee):** Performs the gig and receives funds once released by the Organizer.

---

## 2. Technical Integration Steps

### **Step 1: Musician Onboarding (The Setup)**
Musicians must link their bank account via Stripe Connect Express to receive money.
- **Backend:** `POST /payments/connect-account` creates a Connect ID and returns an onboarding link.
- **Musician App:** `add_bank_account_screen.dart` triggers this link.
- **Storage:** Musician's `stripe_account_id` is saved in Firestore.

### **Step 2: Organizer Gig Funding (The Escrow Deposit)**
When an Organizer hires a musician, they must fund the gig.
- **Backend:** `POST /payments/create-payment-intent` creates a Stripe `PaymentIntent`.
- **Organizer App:** `booking_details_screen.dart` (or hire flow) uses the Stripe Payment Sheet to collect the payment.
- **Success:** Stripe Webhook marks the booking status as `Payment in Escrow`.

### **Step 3: Organizer Release (The Release Trigger)**
The Organizer manually triggers the release after the performance.
- **UI:** `BookingDetailsScreen` (Organizer App) has the **"Release Payment"** button.
- **Backend Endpoint:** `POST /bookings/{id}/release`
- **Logic:**
    1. Verify caller is the Organizer.
    2. Verify booking is in `Payment in Escrow` status.
    3. Call `stripe.Transfer.create()` to move money from Platform -> Musician's `stripe_account_id`.
    4. Update Firestore status to `Payment Released`.

### **Step 4: Webhooks (Synchronization)**
Listen for Stripe events to automate status updates:
- `payment_intent.succeeded`: Confirm gig is funded.
- `transfer.created`: Notify musician of incoming funds.
- `account.updated`: Confirm musician is ready to receive payments.

---

## 3. UI Requirements
| Screen | Component | Action |
| :--- | :--- | :--- |
| **Organizer App** | `BookingDetailsScreen` | "Release Payment" button must call the backend release API. |
| **Musician App** | `WalletOverviewScreen` | Show incoming transfers once released by organizer. |
| **Admin Portal** | `Payments/page.tsx` | View all held/released funds for system oversight. |
