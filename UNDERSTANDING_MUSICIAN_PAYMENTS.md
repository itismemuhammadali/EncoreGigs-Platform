# Musician App: Earnings & Payout Understanding

This document maps how Musicians track their earnings, manage escrowed funds, and request payouts.

## 1. Accessing Payment Settings
**Path:** `ProfileScreen` -> `SettingsIcon` -> `SettingsScreen` -> **Payment & Billing** section.

The section contains two primary navigation buttons:
1.  **Wallet:** Leads to `WalletOverviewScreen` (detailed below).
2.  **Payment Methods:** Leads to `PaymentMethodScreen` for managing payout cards.

## 2. The Wallet Structure
**Location:** `apps/musician/lib/screens/main/wallet_overview_screen.dart`
- **Balance Display:** Shows `Available Balance`, `In Escrow`, and `Total Earned`.
- **Withdrawal:** The "Withdraw Funds" button leads to `RequestPayoutScreen`.
- **Tabs:**
    - **Overview:** General stats and Active Escrow items.
    - **Escrow:** Detailed protection info and locked transaction breakdown.
    - **History:** Full transaction history with export functionality.
    - **Methods:** Direct access to add/remove Bank Accounts and Payment Cards.

## 3. Receiving Payments (Escrow to Available)
- **The Event:** Organizer clicks "Release Payment" (Fiverr model).
- **Process:**
    - Backend executes `stripe.Transfer.create()` from Platform -> Musician Connect Account.
    - Funds move from `In Escrow` to `Available Balance`.
- **Automatic Release:** Funds are automatically released 24 hours after performance completion if no dispute is raised.

## 4. Payment & Payout Methods
### A. Bank Accounts
**Location:** `apps/musician/lib/screens/main/add_bank_account_screen.dart`
- **Usage:** Standard bank transfers for earnings.
- **Fields:** Bank Name, Account Type, Routing Number, Account Number.

### B. Payment Cards (Debit Cards)
**Location:** `apps/musician/lib/screens/main/payment_method_screen.dart` & `add_payment_card_screen.dart`
- **Usage:** Typically used for **Instant Payouts** (sending earnings directly to a debit card) or paying for premium upgrades (e.g., "Featured Artist").
- **Stripe Mapping:** Used as an `external_account` for payouts or a `PaymentMethod` for upgrades.

---

## 5. Summary of Musician Roles
1.  **Service Provider:** Performs the gig to "earn" the escrowed funds.
2.  **Payee:** Receives the transfer once the Organizer/Admin authorizes the release.
3.  **Withdrawer:** Moves funds from their Stripe Connect balance to their personal bank account or debit card.
