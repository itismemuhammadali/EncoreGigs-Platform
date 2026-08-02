# OnlyGigz Digital Performance Agreement - PDF Contract Generator

## Overview
This feature implements dynamic, downloadable PDF contract generation for the **OnlyGigz** platform based on [`OnlyGigz_Gig_Contract_Template.pdf`](file:///Users/muhammadali3000/development/onlygigz/OnlyGigz_Gig_Contract_Template.pdf).

When an organizer or musician confirms a gig, or when a user/admin clicks **Download Contract (PDF)**, the backend dynamically compiles all booking details, agreed payment terms, escrow status, and electronic signatures into a professional 18-section PDF contract.

---

## Structure of Generated PDF (18 Sections)

1. **Parties**: Organizer & Performer names, business info, emails, and phone numbers.
2. **Event Information**: Event title, venue name, address, date, load-in time, sound check time, performance times, age requirements, and dress code.
3. **Performance Details**: Performance format, set duration, break schedule, and special music requests.
4. **Payment Terms & Escrow**: Performance fee, deposit amount (escrowed), remaining balance, platform fee, and Stripe Escrow status.
5. **Cancellation Policy**: Client cancellation rules, artist cancellation provisions, and force majeure clause.
6. **Venue & Technical Requirements**: Sound provider, stage size, power requirements, hospitality, and merch commission terms.
7. **Legal Terms**: Independent contractor designation, governing law, and OnlyGigz mediation clause.
8. **Digital Acceptance & Signatures**: Electronic signatures, timestamps, SHA-256 digital hash, and unique verification code (`OG-VERIFIED-XXXXXX`).

---

## File Map & Modifications

### 1. PDF Generator Service
- **Path**: `backend/services/contract_service.py`
- **Role**: Uses ReportLab to render a clean, styled 18-section PDF layout with tables, badges, headers, and digital verification.

### 2. Booking Service Data Mapper
- **Path**: `backend/services/booking_service.py`
- **Role**: Fetches live booking documents, organizer profiles, and musician profiles from Firestore, formats all variables, and invokes `generate_gig_contract_pdf()`.

### 3. FastAPI Router Endpoints
- **Path**: `backend/routers/bookings.py`
- **Endpoints**:
  - `GET /bookings/{booking_id}/download-contract`
  - `GET /bookings/{booking_id}/contract/pdf`

---

## UI Integration

The backend endpoints are automatically linked to the existing download buttons across all OnlyGigz client apps:
- **Musician Flutter App**: `apps/musician/lib/screens/main/booking_detail_screen.dart`
- **Organizer Flutter App**: `apps/organizer/lib/screens/profile/my_contracts_screen.dart`
- **Admin Web Portal**: `web/admin_portal/src/app/(dashboard)/contracts/page.tsx`

---

## How to Test Backend PDF Generation

You can test generating a sample contract PDF locally by running:

```bash
cd backend
../.venv/bin/python3 -c "
from services.contract_service import generate_gig_contract_pdf

sample_booking = {
    'booking_id': 'BK-100492',
    'title': 'Summer Sunset Jazz Quartet',
    'price': 1200.00,
    'organizer': {'name': 'Sarah Jenkins', 'company': 'Grand Horizon Lounge', 'email': 'sarah@grandhorizon.com'},
    'musician': {'name': 'Marcus Vance', 'stage_name': 'Marcus Vance Trio', 'email': 'marcus@vancemusic.com'},
    'event': {'event_name': 'Summer Sunset Jazz Night', 'venue_name': 'Grand Horizon Lounge', 'venue_address': '124 Bayfront Promenade', 'date': 'August 15, 2026', 'load_in_time': '5:00 PM', 'sound_check_time': '6:15 PM', 'performance_start': '7:30 PM', 'performance_end': '10:30 PM'},
    'performance': {'type': 'Live Jazz Ensemble', 'duration_hours': 3, 'break_duration_mins': 15},
    'payment': {'performance_fee': 1200.00, 'deposit_amount': 600.00, 'balance_due': 600.00, 'escrow_status': 'FUNDS_HELD_IN_ESCROW'},
    'signatures': {'organizer_signature': 'Sarah Jenkins', 'musician_signature': 'Marcus Vance'}
}

pdf_bytes = generate_gig_contract_pdf(sample_booking)
with open('sample_contract.pdf', 'wb') as f:
    f.write(pdf_bytes)
print('PDF created successfully!')
"
```
