# Admin Portal: Payment Oversight & Escrow Management

This document maps the Admin's role in monitoring transactions and intervening in the Escrow process.

## 1. Dashboard Overview
**Location:** `web/admin_portal/src/app/(dashboard)/dashboard/page.tsx`
- **Key Metrics:** Monitors `Escrow Funds` (total locked) and `Monthly Revenue` (platform commission).
- **Trend Analysis:** Visualizes the `Revenue & Escrow Analytics` chart to compare platform earnings against funds currently held for musicians.
- **Activity Feed:** Live monitoring of backend connectivity and system operations.

## 2. Reports & Analytics
**Location:** `web/admin_portal/src/app/(dashboard)/reports/page.tsx`
- **Revenue Depth:** Provides a dual-axis chart for `Revenue ($)` vs `Bookings`, allowing admins to see the correlation between volume and profit.
- **Growth Tracking:** Monitors musician vs. organizer onboarding to ensure a balanced marketplace for liquidity.

## 3. Payments & Escrow Management
**Location:** `web/admin_portal/src/app/(dashboard)/payments/page.tsx`
- **Transaction Table:** A granular list of all gig payments with their current status (`held` vs `released`).
- **Escrow Control:**
    - **Held in Escrow:** Filter to see all funds currently sitting in the platform's Stripe balance.
    - **Released:** Filter to see successful transfers to musicians.
- **Manual Intervention:**
    - **Release Escrow:** Manually triggers the transfer to the musician (via `PaymentActionModal`).
    - **Process Refund:** Manually triggers a Stripe Refund to the organizer.

## 4. Technical Integration Targets (Single Stripe Account Model)
- **Revenue Calculation:** Platform commission is deducted during the `Transfer` stage from Platform to Musician.
- **Stripe Mapping:** 
    - `Total Escrow Funds` stat -> `stripe.Balance.retrieve()` (specifically the `pending` or `available` balance depending on capture method).
    - `Refund` -> `stripe.Refund.create()`.
    - `Release` -> `stripe.Transfer.create()`.

---

## 5. Summary of Admin Roles
1.  **Overseer:** Monitors the overall financial health and "locked" funds of the platform.
2.  **Mediator:** Intervenes in disputes to either force a release or process a refund.
3.  **Auditor:** Verifies that payments are moving correctly between organizers and musicians.

**DESIGN MANDATE:** All backend integrations must be performed via existing API utilities (`apiRequest`). The visual design, layouts, and component structures of the Admin Portal must remain entirely untouched.
