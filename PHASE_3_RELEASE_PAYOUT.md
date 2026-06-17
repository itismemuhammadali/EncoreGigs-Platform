# Phase 3: The Release & Payout System

**Target:** Implement the "Fiverr-style" release mechanism using the existing "Release Payment" and Admin buttons.

## Implementation Details
1.  **Organizer Release:**
    - Wire the existing "Release Payment" button in the Organizer's `BookingDetailsScreen`.
    - Backend Logic: `stripe.Transfer.create()` moves money from the Platform balance to the Musician's `stripe_account_id`.
    - Update Firestore booking status to `Released`.

2.  **Admin Portal Integration:**
    - Connect the "Release Escrow" button in `web/admin_portal/src/app/(dashboard)/payments/page.tsx` (via `PaymentActionModal`) to the same backend transfer logic.
    - Connect the "Process Refund" button to `stripe.Refund.create()` to return money to the Organizer.

3.  **Musician Wallet Synchronization:**
    - Update the Musician's `WalletOverviewScreen` to fetch the real balance from the Stripe Connect Account via a new backend endpoint `GET /payments/balance`.

---

**CRITICAL MANDATE:** 
THE DESIGN AND UI OF THE APPLICATIONS (MUSICIAN APP, ORGANIZER APP, AND ADMIN PORTAL) MUST NOT BE MODIFIED IN ANY WAY. NO BUTTONS, TEXT, OR COLORS SHOULD BE CHANGED. ALL WORK IS STRICTLY LOGICAL AND DATA-DRIVEN.
