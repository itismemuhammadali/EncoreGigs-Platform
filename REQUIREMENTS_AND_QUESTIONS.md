# OnlyGigz - Requirements and Questions Document

---

## Executive Summary
This document outlines the **legal & compliance requirements** for the OnlyGigz platform, alongside **operational, architectural, and financial questions** identified through codebase analysis and client requirements.

The contents cover all four main system components:
1. **Musician Mobile App** (`apps/musician`)
2. **Organizer Mobile App** (`apps/organizer`)
3. **Web Admin Portal** (`web/admin_portal`)
4. **Gig Scraper & Backend Engine** (`scraper` & `backend`)

---

## Part 1: Requirements (Legal, Compliance & Policy Documents)

To launch and operate OnlyGigz legally and securely, the following documentation and policies must be drafted and integrated into all client-facing applications:

### 1. Terms & Conditions (T&C)
* **User Accounts & Eligibility**: Rules governing account creation, verification, age requirements, and profile accuracy for both musicians and event organizers.
* **Platform Role**: Explicit statement that OnlyGigz acts as a venue/marketplace facilitating connections between musicians and event organizers, outlining liability limits.
* **Conduct & Acceptable Use**: Rules against spam, harassment, circumvention of platform payments, and fraudulent gig postings.

### 2. Privacy Policy
* **Data Collection & Usage**: Disclosure of personal data collected (name, email, location, payment info, audio clips, portfolio media, device metadata).
* **Third-Party Services**: Transparent disclosure of integrated services including Firebase (Auth, Firestore, Storage), Stripe (Payments & Connect payouts), and OpenAI/Gemini (AI classification).
* **Data Scraping Transparency**: Informing users how publicly available gig data is ingested, processed, and displayed on the platform.
* **Data Retention & Deletion**: Instructions for users on how to request profile deletion and data export in compliance with privacy regulations (GDPR / CCPA).

### 3. Terms of Service (ToS)
* **Service Agreements & Bookings**: Binding agreement terms between organizers and musicians upon gig acceptance.
* **Cancellation & Refund Policies**: Clear conditions for booking cancellations, refund eligibility, notice periods, and emergency no-shows.
* **Payment & Escrow Terms**: Terms detailing how funds are held prior to gig completion and released upon verification.

### 4. Copyright & Scraped Content Policy (DMCA / Fair Use)
* **External Scraped Gigs**: Legal notice explaining that scraped gig listings originate from public third-party sources (e.g., Facebook Marketplace, Craigslist).
* **Takedown Request Mechanism**: A clear process allowing original venue owners or gig posters to request removal of their scraped listing or claim ownership of their gig account on OnlyGigz.

### 5. Payment, Escrow & Payout Policy
* **Platform Service Fees**: Breakdown of service fees charged to musicians and organizers per transaction.
* **Stripe Connect & Payout Terms**: Requirements for Stripe onboarding, identity verification (KYC), bank payout schedules, and dispute/chargeback responsibilities.

### 6. About Us & Company Overview Document
* **Store Submission & Compliance**: Official company biography and mission statement required for Apple App Store and Google Play Store developer review and publication.
* **User & Partner Transparency**: Informational content explaining the OnlyGigz origin, core team background, marketplace values, and service offerings to users.

---

## Part 2: Questions & Operational Decisions

---

### Question 1: Scraped Gigs Workflow & Communication Bridge
* **Context**: The Scraper module ingests publicly listed gigs from Facebook Marketplace, Craigslist, and other external sources. The original posters of these gigs are not registered users on OnlyGigz.
* **Problem**: When an OnlyGigz musician applies to a scraped gig through the Musician app, the original external poster does not have an OnlyGigz account to receive notifications or view the applicant's profile.
* **Questions for Client**:
  1. How should communication be established between an OnlyGigz musician and an external gig poster?
  2. Should OnlyGigz automatically send an email/SMS notification to the external contact with a magic link to view the musician's profile and accept/decline?
  3. Should the platform invite the external poster to claim their gig by registering on the Organizer app?
  4. Alternatively, should an OnlyGigz Admin act as a liaison/relay to manually forward applications to external posters?
  5. Should musicians simply be redirected to the original external link (Craigslist / Facebook post) to apply directly on the external platform?

---

### Question 2: Support & Customer Service Chat System Across Apps
* **Context**:
  * In the **Musician App** (`lib/screens/main/help_center_screen.dart` & `live_chat_screen.dart`), a "Live Chat" screen exists ("Sarah from Support"), but it currently operates with mock static data and is not connected to a live backend or database.
  * In the **Organizer App**, there is currently **no Help & Support screen** or live chat interface implemented.
  * In the **Web Admin Portal**, there is currently no admin dashboard interface for viewing, assigning, or responding to incoming support chats.
* **Questions for Client**:
  1. **Admin Portal Support UI**: Should we build a real-time Customer Support Dashboard in `web/admin_portal` connected to a Firestore `support_chats` collection so admins can chat live with app users?
  2. **Organizer App Parity**: Should we implement a dedicated "Help & Support Center" screen in the Organizer App mirroring the Musician App?
  3. **Third-Party vs. Custom**: Should we proceed with building custom Firestore live chat support, or integrate a third-party customer support widget (e.g., Intercom, Crisp, Zendesk)?

---

### Question 3: Scraper Module UI & Data Depth in Web Admin Portal
* **Context**: Currently, on the Web Admin Portal (`/scraper` page), the "Recently Imported Gigs" table displays minimal fields: *Title, Source, AI Classification, Confidence Score, Flags, and Imported Date*.
* **Problem**: Admins approving or publishing scraped gigs cannot see the full details (pay range, duration, images, description, location) directly in the table or modal, nor can they preview the original listing link.
* **Questions for Client**:
  1. **Expanded Columns & Popup Details**: Should the Scraper table / detail modal be upgraded to display all extracted fields including Budget/Pay Range, Event Date & Duration, Location/Venue, Cover Images, and Full Gig Description?
  2. **Original Listing Link**: Should every scraped gig row feature a direct "Original Source URL" button opening the original Craigslist/Facebook post in a new browser tab for admin verification before publishing?
  3. **Auto-Publish Rules**: Should scraped gigs with high AI confidence (e.g., >95%) be auto-published to the app, or should ALL scraped gigs require manual admin approval ("Show in App")?

---

### Question 4: Two-Factor Authentication (2FA) Scope Across Platforms
* **Context**:
  * The **Musician App** includes a Two-Factor Authentication screen (`two_factor_authentication_screen.dart`) under Account Settings.
  * Neither the **Organizer App** nor the **Web Admin Portal** currently features 2FA settings or enforcement.
* **Questions for Client**:
  1. **Platform Scope**: Is 2FA intended to be supported and enforced across all three platforms (Musician App, Organizer App, and Web Admin Portal)?
  2. **Admin Security**: Given that the Web Admin Portal manages financial payouts, scraper engines, and user disputes, should 2FA be **mandatory** for Admin account logins?
  3. **Authentication Method**: Which 2FA mechanisms should be supported (SMS OTP via Firebase Phone Auth, Email OTP, or Authenticator App TOTP)?

---

### Question 5: Financial Settlement in Admin Dispute Management
* **Context**: In `web/admin_portal/src/app/(dashboard)/disputes/page.tsx`, resolving a dispute currently only changes the status flag or triggers user warnings/suspensions. It does not perform financial actions on held funds.
* **Questions for Client**:
  1. **Admin Financial Actions**: When an Admin resolves an open dispute, should the UI provide explicit financial controls:
     * Full Refund to Organizer
     * Full Release to Musician
     * Custom Split (e.g. 50% Refund / 50% Payout)
  2. **Automated Stripe Triggering**: Should resolving a dispute automatically trigger the corresponding Stripe Refund or Stripe Transfer API calls immediately?

---

### Question 6: Featured Profile & Gig Upgrades (Monetization Engine)
* **Context**: Both the Musician App (`featured_upgrade_screen.dart`) and Web Admin Portal (`/featured` route) include provisions for "Featured Profile" and "Featured Gig" placements.
* **Questions for Client**:
  1. **Pricing & Subscription Plans**: What are the pricing tiers for featured promotions (e.g. $9.99/week, $29.99/month)?
  2. **Payment Gateway**: Should featured profile upgrades be billed via Apple In-App Purchase / Google Play Billing on mobile, or via Stripe Web Checkout?
  3. **Search Priority**: How should featured musicians and gigs be prioritized in search and feed screens (top placement banner vs highlighted card styling)?

---

### Question 7: Sharing Signed Digital Contracts with Users
* **Context**: Digital contract signing is completed in-app via signature canvas, but there is currently no email or export mechanism to deliver a copy of the signed contract to the users.
* **Questions for Client**:
  1. **Contract Delivery**: How should signed contracts be shared with the organizer and musician once signed?
  2. **Email Delivery**: Should an automated copy of the signed contract be emailed to both parties upon completion?
  3. **In-App PDF Download**: Should users be able to download a PDF copy directly within the mobile apps, or keep it purely as an in-app text record?

---

### Question 8: Target Geographic Regions & International Rollout Scope
* **Context**: Defining the geographical boundaries of the platform impacts payment currency, phone verification, legal compliance, and Stripe Connect capabilities.
* **Questions for Client**:
  1. **Operational Countries**: In which country or countries is the OnlyGigz app intended to launch and operate (e.g., United States only, Canada, UK, Australia, or Global)?
  2. **Multi-Currency Support**: Should the app support multiple currencies (USD, CAD, EUR, GBP) or strictly operate in a single currency (USD)?
  3. **Phone & Identity Verification**: Are phone verification and identity checks restricted to domestic phone formats or open internationally?

---

### Question 9: Platform Fee Percentage & Refund/Cancellation Policy
* **Context**: The platform revenue model depends on commission fees collected during gig completion, as well as handling fee retention during cancellations.
* **Questions for Client**:
  1. **Commission Fee Percentage**: What exact percentage (or fixed fee) will OnlyGigz deduct as a platform commission fee on every completed gig transaction?
  2. **Refund Charges & Retention**: Does the platform retain any administrative fee or percentage when a refund is processed for a cancelled job?
  3. **Cancellation Rules**: What are the penalty structures or non-refundable fee rules when an organizer or musician cancels a booking close to the event date?

---

## Complete Requirements & Questions Summary Table

| Category | Item | Current Codebase Status | Action Required |
| :--- | :--- | :--- | :--- |
| **Legal** | Terms & Conditions | Missing | Drafting & In-app integration |
| **Legal** | Privacy Policy | Missing | Drafting & In-app integration |
| **Legal** | Terms of Service | Missing | Drafting & In-app integration |
| **Legal** | Copyright / DMCA Takedown | Missing | Policy & Takedown Form creation |
| **Legal** | About Us & Company Overview | Missing | Drafting for Apple & Google App Store submission |
| **Workflow** | Scraped Gig Applications | Musician can apply in-app | Define communication bridge for external posters |
| **Feature** | Support Live Chat | UI exists in Musician app (mock data) | Build Admin Portal Support UI & Organizer App Support Screen |
| **Feature** | Scraper Admin UI | Table shows basic summary | Expand table/modals with full gig details & source URLs |
| **Security**| Two-Factor Auth (2FA) | Musician App UI only | Decide on 2FA scope for Organizer App & Web Admin Portal |
| **Finance** | Dispute Financials | Status toggle only | Add refund, release, and partial split actions to Admin UI |
| **Revenue** | Featured Upgrades | UI screen present | Define pricing tiers, billing method (IAP vs Stripe), and feed logic |
| **Legal** | Contract Delivery | Signature canvas present | Define email delivery or in-app PDF export for signed contracts |
| **Scope**   | Target Regions | App configured for US | Define operating countries, currency, and international rollout |
| **Finance** | Platform Fee & Refund Policy | Escrow buttons wired | Define exact commission %, fee retention on refunds & cancellations |
