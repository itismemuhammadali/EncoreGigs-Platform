# Organization App: Payment & Hiring Flow Understanding

This document maps the current logical flow of the Organizer application regarding fund management, hiring, escrow, and payment release.

## 1. Fund Management (The Wallet)
**Location:** `apps/organizer/lib/screens/profile/wallet_screen.dart`
- **Current Logic:** The app maintains a virtual `_balance`.
- **Add Funds:** 
    - Organizers can add money to their internal wallet via `AddFundsSheet`.
    - This currently opens `AddPaymentMethodScreen` where Card (Visa/Mastercard) details are entered.
- **Stripe Integration Target:** 
    - Instead of just updating a local variable, "Add Funds" must trigger a **Stripe PaymentIntent**.
    - The funds move from the Organizer's Card/Bank into the **Platform's Stripe Account**.

## 2. The Hiring Flow (Moving to Escrow)
**Path:** `ApplicantsScreen` -> `HireMusicianDialog` -> `PaymentScreen` -> `ContractScreen`
- **Hire Action:** When an Organizer chooses a musician, they are directed to the `PaymentScreen`.
- **Escrow Commitment:** 
    - The `PaymentScreen` checks if the `walletBalance >= gigAmount`.
    - If funds are sufficient, the user proceeds to the `ContractScreen`.
- **Contract & Signature:** 
    - The Organizer signs the digital contract.
    - Upon clicking "Sign & Confirm", the backend `confirm_booking` is called.
- **Logical Escrow:** 
    - In the database, the booking status becomes `Payment in Escrow`.
    - **Note:** In the Stripe model, the money is already in our platform account; we are now logically earmarking it for this specific musician.

## 3. Post-Gig Completion (The Release)
**Location:** `apps/organizer/lib/screens/profile/booking_details_screen.dart`
- **Release Trigger:** The Organizer manually clicks the **"Release Payment"** button after the performance is finished.
- **Current UI:** Opens `ReleasePaymentDialog` which currently only updates the Firestore status to `payment released`.
- **Stripe Integration Target:** 
    - This button must now trigger a **Stripe Transfer**.
    - Funds move from the **Platform Stripe Account** to the **Musician's Connected Stripe Account**.

## 4. Dispute Resolution & Refunds
**Scenario:** A gig is not completed satisfactorily, or a breach of contract occurs.
- **Trigger:** The Organizer or Musician files a dispute (via `DisputeManagementScreen`).
- **Resolution:** If the dispute is resolved in favor of the Organizer:
    - **Stripe Action:** The backend triggers a `stripe.Refund.create()` using the original `charge_id` (from the Escrow deposit).
    - **Flow:** Funds move from the **Platform Stripe Account** back to the **Organizer's original payment method**.
- **Database Status:** The booking is marked as `Refunded` and the escrow lock is removed.

## 5. Key UI Components Involved
| Component | Purpose | Stripe Mapping |
| :--- | :--- | :--- |
| `AddPaymentMethodScreen` | Collects Card info. | Create Stripe `PaymentMethod`. |
| `AddBankAccountScreen` | Collects Bank info. | (Usually for Musicians, but present here). |
| `PaymentScreen` | Validates Escrow funds. | Verify previous "Add Funds" transaction. |
| `ContractScreen` | Finalizes the agreement. | Final logical lock on funds. |
| `ReleasePaymentDialog` | Triggers the payout. | Execute `stripe.Transfer`. |

---

## 5. Summary of Organizer Roles
1.  **Depositor:** Moves money from personal card/bank to OnlyGigz Platform.
2.  **Escrow Authorized Signatory:** Signs the contract to lock funds for a specific gig.
3.  **Approver:** Manually authorizes the final transfer to the musician.
