# Phase 1: Core Stripe Infrastructure

**Target:** Establish a secure, robust foundation for all Stripe operations without modifying any UI components.

## Implementation Details
1.  **Environment Configuration:**
    - Securely inject provided Stripe API keys into `backend/.env`.
    - Initialize the Stripe client in `backend/services/payment_service.py`.

2.  **Stripe Service Layer:**
    - Develop `PaymentService.create_customer(user_id, email)` for Organizers.
    - Develop `PaymentService.create_connected_account(user_id)` for Musicians.
    - Develop `PaymentService.get_account_onboarding_link(account_id)` to generate the musician setup URL.

3.  **Webhook Router:**
    - Initialize `backend/routers/payments.py` with a `/stripe/webhook` endpoint.
    - Implement the logic to verify Stripe signatures.
    - Stub listeners for `payment_intent.succeeded` and `account.updated`.

4.  **Database Extensions:**
    - Ensure `organizers` and `musicians` collections in Firestore have fields for `stripe_id` and `stripe_status`.

---

**CRITICAL MANDATE:** 
THE DESIGN AND UI OF THE APPLICATIONS (MUSICIAN APP, ORGANIZER APP, AND ADMIN PORTAL) MUST NOT BE MODIFIED IN ANY WAY. NO BUTTONS, TEXT, OR COLORS SHOULD BE CHANGED. ALL WORK IS STRICTLY LOGICAL AND DATA-DRIVEN.
