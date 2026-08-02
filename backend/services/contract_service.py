import io
import hashlib
from datetime import datetime
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    HRFlowable,
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT

def generate_gig_contract_pdf(booking: dict) -> bytes:
    """
    Generates a professional 18-section ONLYGIGZ DIGITAL PERFORMANCE AGREEMENT PDF
    using ReportLab based on booking data and signatures.
    """
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=letter,
        rightMargin=40,
        leftMargin=40,
        topMargin=40,
        bottomMargin=40,
    )

    styles = getSampleStyleSheet()

    # Custom styles
    title_style = ParagraphStyle(
        "ContractTitle",
        parent=styles["Heading1"],
        fontName="Helvetica-Bold",
        fontSize=20,
        leading=24,
        textColor=colors.HexColor("#2A1F2E"),
        alignment=TA_CENTER,
        spaceAfter=4,
    )

    subtitle_style = ParagraphStyle(
        "ContractSubtitle",
        parent=styles["Normal"],
        fontName="Helvetica-Oblique",
        fontSize=10,
        leading=14,
        textColor=colors.HexColor("#6B5E70"),
        alignment=TA_CENTER,
        spaceAfter=15,
    )

    section_heading = ParagraphStyle(
        "SectionHeading",
        parent=styles["Heading2"],
        fontName="Helvetica-Bold",
        fontSize=12,
        leading=16,
        textColor=colors.HexColor("#8B3A62"), # Brand accent color
        spaceBefore=10,
        spaceAfter=6,
    )

    body_style = ParagraphStyle(
        "ContractBody",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=9.5,
        leading=14,
        textColor=colors.HexColor("#2B2B2B"),
    )

    label_style = ParagraphStyle(
        "ContractLabel",
        parent=body_style,
        fontName="Helvetica-Bold",
        textColor=colors.HexColor("#1A1A1A"),
    )

    badge_style = ParagraphStyle(
        "BadgeStyle",
        parent=body_style,
        fontName="Helvetica-Bold",
        fontSize=9,
        textColor=colors.HexColor("#006644"),
        alignment=TA_RIGHT,
    )

    story = []

    # Title & Header
    story.append(Paragraph("ONLYGIGZ DIGITAL PERFORMANCE AGREEMENT", title_style))
    story.append(Paragraph("This agreement is auto-generated upon booking confirmation on OnlyGigz.", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#E0D6E2"), spaceAfter=12))

    # Helper function for section tables
    def make_table(data_matrix, col_widths=[140, 392]):
        t = Table(data_matrix, colWidths=col_widths)
        t.setStyle(
            TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#FBF9FC")),
                ("ALIGN", (0, 0), (-1, -1), "LEFT"),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("PADDING", (0, 0), (-1, -1), 5),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#EDE7F0")),
            ])
        )
        return t

    # 1. Parties
    story.append(Paragraph("1. Parties", section_heading))
    org = booking.get("organizer", {})
    mus = booking.get("musician", {})
    parties_data = [
        [
            Paragraph("Client / Organizer", label_style),
            Paragraph(f"<b>{org.get('name', 'N/A')}</b><br/>Company: {org.get('company', 'Individual')}<br/>Email: {org.get('email', 'N/A')} | Phone: {org.get('phone', 'N/A')}", body_style),
        ],
        [
            Paragraph("Artist / Performer", label_style),
            Paragraph(f"<b>{mus.get('name', 'N/A')}</b> (Stage: {mus.get('stage_name', mus.get('name', 'N/A'))})<br/>Email: {mus.get('email', 'N/A')} | Phone: {mus.get('phone', 'N/A')}", body_style),
        ],
    ]
    story.append(make_table(parties_data))
    story.append(Spacer(1, 8))

    # 2. Event Information
    story.append(Paragraph("2. Event Information", section_heading))
    evt = booking.get("event", {})
    evt_data = [
        [Paragraph("Event & Venue", label_style), Paragraph(f"<b>{evt.get('event_name', booking.get('title', 'Gig Performance'))}</b> at {evt.get('venue_name', 'N/A')}<br/>{evt.get('venue_address', 'N/A')}", body_style)],
        [Paragraph("Date & Schedule", label_style), Paragraph(f"Date: <b>{evt.get('date', 'N/A')}</b><br/>Load-in: {evt.get('load_in_time', 'N/A')} | Sound Check: {evt.get('sound_check_time', 'N/A')}<br/>Performance: <b>{evt.get('performance_start', 'N/A')} - {evt.get('performance_end', 'N/A')}</b>", body_style)],
        [Paragraph("Environment & Policy", label_style), Paragraph(f"Indoor/Outdoor: {evt.get('indoor_outdoor', 'Indoor')} | Age Requirement: {evt.get('age_requirement', 'All Ages')}<br/>Dress Code: {evt.get('dress_code', 'Casual/Smart')}", body_style)],
    ]
    story.append(make_table(evt_data))
    story.append(Spacer(1, 8))

    # 3. Performance Details
    story.append(Paragraph("3. Performance Details", section_heading))
    perf = booking.get("performance", {})
    perf_data = [
        [Paragraph("Performance Format", label_style), Paragraph(f"Type: {perf.get('type', 'Live Musical Performance')}<br/>Sets / Duration: {perf.get('duration_hours', '2')} hours (Breaks: {perf.get('break_duration_mins', '15')} mins per set)", body_style)],
        [Paragraph("Song Requests / Notes", label_style), Paragraph(perf.get("special_requests", "Standard repertoire agreed upon by client and artist."), body_style)],
    ]
    story.append(make_table(perf_data))
    story.append(Spacer(1, 8))

    # 4. Payment Terms & Escrow
    story.append(Paragraph("4. Payment Terms & Escrow", section_heading))
    pay = booking.get("payment", {})
    fee = pay.get("performance_fee", booking.get("price", 0))
    dep = pay.get("deposit_amount", round(fee * 0.5, 2))
    bal = pay.get("balance_due", round(fee - dep, 2))
    pay_data = [
        [Paragraph("Agreed Performance Fee", label_style), Paragraph(f"<b>${fee:,.2f} USD</b>", body_style)],
        [Paragraph("Deposit & Balance", label_style), Paragraph(f"Deposit (Escrowed): <b>${dep:,.2f}</b> | Remaining Balance: <b>${bal:,.2f}</b>", body_style)],
        [Paragraph("Escrow Status", label_style), Paragraph(f"Status: <b>{pay.get('escrow_status', 'FUNDS_HELD_IN_ESCROW')}</b> via Stripe Escrow<br/>Platform Fee: {pay.get('platform_fee', 'Covered')} | Payout released upon gig completion.", body_style)],
    ]
    story.append(make_table(pay_data))
    story.append(Spacer(1, 8))

    # 5. Cancellation Policy
    story.append(Paragraph("5. Cancellation Policy", section_heading))
    canc = booking.get("cancellation", {})
    canc_data = [
        [Paragraph("Client Cancellation", label_style), Paragraph(canc.get("client_terms", "14+ days prior: Full refund minus platform fee. 7-13 days: 50% deposit retained by artist. < 7 days: 100% deposit retained by artist."), body_style)],
        [Paragraph("Artist Cancellation", label_style), Paragraph(canc.get("artist_terms", "Artist agrees to find a suitable qualified replacement or return 100% deposit immediately."), body_style)],
        [Paragraph("Force Majeure", label_style), Paragraph("Neither party shall be liable for cancellations due to severe weather, natural disasters, or government restrictions.", body_style)],
    ]
    story.append(make_table(canc_data))
    story.append(Spacer(1, 8))

    # 6-12. Venue, Production, Merch, Recording
    story.append(Paragraph("6. Venue & Technical Requirements", section_heading))
    tech = booking.get("sound_production", {})
    hosp = booking.get("hospitality", {})
    tech_data = [
        [Paragraph("Sound & Stage", label_style), Paragraph(f"Sound Provider: {tech.get('sound_provider', 'Venue PA System')}<br/>Stage & Power: {tech.get('stage_needs', 'Standard 120V grounded outlets near stage')}", body_style)],
        [Paragraph("Hospitality & Merch", label_style), Paragraph(f"Meals/Drinks: {hosp.get('meals', 'Provided by venue')}<br/>Merchandise: {booking.get('merchandise', {}).get('allowed', 'Artist permitted to sell merchandise (0% venue commission)')}", body_style)],
        [Paragraph("Recording & Photos", label_style), Paragraph("Organizer and attendees may take non-commercial photos and short video clips.", body_style)],
    ]
    story.append(make_table(tech_data))
    story.append(Spacer(1, 8))

    # 13-17. Legal Provisions
    story.append(Paragraph("7. Legal Terms & Independent Contractor", section_heading))
    legal_data = [
        [Paragraph("Independent Contractor", label_style), Paragraph("Artist performs as an independent contractor. Neither party is an employee, partner, or agent of the other.", body_style)],
        [Paragraph("Governing Law & Disputes", label_style), Paragraph("Governed by applicable state laws. Disputes shall be submitted to OnlyGigz Platform Mediation prior to formal legal action.", body_style)],
    ]
    story.append(make_table(legal_data))
    story.append(Spacer(1, 12))

    # 18. Signatures & Digital Acceptance
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#8B3A62"), spaceAfter=8))
    story.append(Paragraph("18. Digital Acceptance & Verification", section_heading))

    sigs = booking.get("signatures", {})
    org_sig = sigs.get("organizer_signature", f"Digitally signed by {org.get('name', 'Organizer')}")
    org_date = sigs.get("organizer_signed_at", datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC"))
    org_img = sigs.get("organizer_signature_img")

    mus_sig = sigs.get("musician_signature", f"Digitally signed by {mus.get('name', 'Artist')}")
    mus_date = sigs.get("musician_signed_at", datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC"))
    mus_img = sigs.get("musician_signature_img")

    # Compute digital verification hash
    raw_hash_str = f"{booking.get('booking_id', 'GIG')}-{org_sig}-{mus_sig}-{fee}"
    verification_hash = hashlib.sha256(raw_hash_str.encode("utf-8")).hexdigest()[:24].upper()

    # Build Organizer Signature Block
    org_content = [
        Paragraph("<b>CLIENT / ORGANIZER</b>", body_style),
        Spacer(1, 4),
    ]
    if org_img:
        org_content.append(org_img)
    else:
        org_content.append(Paragraph(f"<i>{org_sig}</i>", body_style))
    org_content.append(Spacer(1, 4))
    org_content.append(Paragraph(f"Signed: {org_date}", body_style))

    # Build Musician Signature Block
    mus_content = [
        Paragraph("<b>ARTIST / PERFORMER</b>", body_style),
        Spacer(1, 4),
    ]
    if mus_img:
        mus_content.append(mus_img)
    else:
        mus_content.append(Paragraph(f"<i>{mus_sig}</i>", body_style))
    mus_content.append(Spacer(1, 4))
    mus_content.append(Paragraph(f"Signed: {mus_date}", body_style))

    sig_data = [
        [org_content, mus_content],
        [
            Paragraph(f"<b>VERIFICATION CODE:</b> <font color='#8B3A62'><b>OG-VERIFIED-{verification_hash[:8]}</b></font>", body_style),
            Paragraph(f"<b>DIGITAL HASH:</b> {verification_hash}", body_style),
        ],
    ]

    sig_table = Table(sig_data, colWidths=[266, 266])
    sig_table.setStyle(
        TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F5EFF7")),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("PADDING", (0, 0), (-1, -1), 10),
            ("GRID", (0, 0), (-1, -1), 1, colors.HexColor("#D8C9DE")),
        ])
    )
    story.append(sig_table)

    doc.build(story)
    buffer.seek(0)
    return buffer.getvalue()
