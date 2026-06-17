# Phase 2: Onboarding & Funding Flow

**Target:** Connect existing UI "Save" and "Add" buttons to Stripe to enable the initial deposit of funds into Escrow.

## Implementation Details
1.  **Organizer - Adding Cards:**
    - Wire the existing "Save Payment Method" button in `apps/organizer/lib/screens/profile/add_payment_method_screen.dart` to tokenize card details via `flutter_stripe`.
    - Send the token to the backend to attach the card to the Organizer's `Stripe Customer` object.

2.  **Musician - Linking Bank:**
    - Wire the existing "Add Bank Account" button in `apps/musician/lib/screens/main/add_bank_account_screen.dart` to call the backend and receive a Stripe Connect Onboarding link.
    - Open the link in a browser; upon completion, update the Musician's status in Firestore via Stripe Webhooks.

3.  **The Escrow Deposit:**
    - Update the backend `confirm_booking` logic.
    - When an Organizer signs the contract, the backend triggers a `stripe.PaymentIntent.create()` with `capture_method=automatic`.
    - Funds move from the Organizer's card to the **OnlyGigz Platform Account** (Held as Escrow).

---

**CRITICAL MANDATE:** 
THE DESIGN AND UI OF THE APPLICATIONS (MUSICIAN APP, ORGANIZER APP, AND ADMIN PORTAL) MUST NOT BE MODIFIED IN ANY WAY. NO BUTTONS, TEXT, OR COLORS SHOULD BE CHANGED. ALL WORK IS STRICTLY LOGICAL AND DATA-DRIVEN.
