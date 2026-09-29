import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml, OxmlElement
from docx.oxml.ns import nsdecls, qn

def create_document():
    doc = docx.Document()

    # Page Margins: Standard 1 inch
    sections = doc.sections
    for section in sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)

    # Palette
    COLOR_PRIMARY = RGBColor(24, 43, 73)      # Dark Navy #182B49
    COLOR_SECONDARY = RGBColor(37, 99, 235)   # Royal Blue #2563EB
    COLOR_ACCENT = RGBColor(16, 185, 129)     # Emerald Green #10B981
    COLOR_TEXT = RGBColor(31, 41, 55)         # Charcoal Gray #1F2937
    COLOR_MUTED = RGBColor(100, 116, 139)     # Slate Gray #64748B
    COLOR_CODE = RGBColor(15, 23, 42)         # Code Text #0F172A

    # Helper: Set Cell Shading
    def set_cell_background(cell, fill_hex):
        shading_xml = f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>'
        cell._tc.get_or_add_tcPr().append(parse_xml(shading_xml))

    # Helper: Set Cell Padding
    def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
        tcPr = cell._tc.get_or_add_tcPr()
        tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
        tcPr.append(tcMar)

    # Helper: Callout Box
    def add_callout_box(text, title="NOTE", box_type="info"):
        tbl = doc.add_table(rows=1, cols=1)
        tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = tbl.cell(0, 0)
        cell.width = Inches(6.5)
        
        fill_color = "EFF6FF" if box_type == "info" else ("FEF2F2" if box_type == "warning" else "F0FDF4")
        border_color = "2563EB" if box_type == "info" else ("EF4444" if box_type == "warning" else "10B981")
        
        tcPr = cell._tc.get_or_add_tcPr()
        shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_color}"/>')
        borders = parse_xml(f'<w:tcBorders {nsdecls("w")}><w:top w:val="none"/><w:left w:val="single" w:sz="24" w:space="0" w:color="{border_color}"/><w:bottom w:val="none"/><w:right w:val="none"/></w:tcBorders>')
        tcPr.append(shd)
        tcPr.append(borders)
        set_cell_margins(cell, top=140, bottom=140, left=200, right=200)
        
        p = cell.paragraphs[0]
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(4)
        run_title = p.add_run(f"[{title.upper()}]\n")
        run_title.bold = True
        run_title.font.name = "Segoe UI"
        run_title.font.size = Pt(10)
        run_title.font.color.rgb = COLOR_SECONDARY if box_type == "info" else (RGBColor(239, 68, 68) if box_type == "warning" else COLOR_ACCENT)
        
        run_text = p.add_run(text)
        run_text.font.name = "Segoe UI"
        run_text.font.size = Pt(9.5)
        run_text.font.color.rgb = COLOR_TEXT
        doc.add_paragraph().paragraph_format.space_after = Pt(6)

    # Helper: Code Block
    def add_code_block(code_text):
        tbl = doc.add_table(rows=1, cols=1)
        tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = tbl.cell(0, 0)
        cell.width = Inches(6.5)
        set_cell_background(cell, "F8FAFC")
        tcPr = cell._tc.get_or_add_tcPr()
        borders = parse_xml(f'<w:tcBorders {nsdecls("w")}><w:top w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/><w:left w:val="single" w:sz="16" w:space="0" w:color="64748B"/><w:bottom w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/><w:right w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/></w:tcBorders>')
        tcPr.append(borders)
        set_cell_margins(cell, top=120, bottom=120, left=180, right=180)
        
        p = cell.paragraphs[0]
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.line_spacing = 1.15
        run = p.add_run(code_text)
        run.font.name = "Consolas"
        run.font.size = Pt(9)
        run.font.color.rgb = COLOR_CODE
        doc.add_paragraph().paragraph_format.space_after = Pt(6)

    # Heading Helpers
    def add_h1(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(20)
        p.paragraph_format.space_after = Pt(8)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.bold = True
        run.font.name = "Segoe UI"
        run.font.size = Pt(16)
        run.font.color.rgb = COLOR_PRIMARY
        return p

    def add_h2(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(14)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.bold = True
        run.font.name = "Segoe UI"
        run.font.size = Pt(13)
        run.font.color.rgb = COLOR_SECONDARY
        return p

    def add_h3(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(10)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.bold = True
        run.font.name = "Segoe UI"
        run.font.size = Pt(11)
        run.font.color.rgb = COLOR_TEXT
        return p

    def add_body(text, bold_prefix=None, italic=False):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(5)
        p.paragraph_format.line_spacing = 1.15
        if bold_prefix:
            r_bold = p.add_run(bold_prefix)
            r_bold.bold = True
            r_bold.font.name = "Segoe UI"
            r_bold.font.size = Pt(10)
            r_bold.font.color.rgb = COLOR_TEXT
        run = p.add_run(text)
        run.font.name = "Segoe UI"
        run.font.size = Pt(10)
        run.font.italic = italic
        run.font.color.rgb = COLOR_TEXT
        return p

    def add_bullet(text, bold_prefix=None):
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(3)
        p.paragraph_format.line_spacing = 1.15
        if bold_prefix:
            r_bold = p.add_run(bold_prefix)
            r_bold.bold = True
            r_bold.font.name = "Segoe UI"
            r_bold.font.size = Pt(10)
            r_bold.font.color.rgb = COLOR_TEXT
        run = p.add_run(text)
        run.font.name = "Segoe UI"
        run.font.size = Pt(10)
        run.font.color.rgb = COLOR_TEXT
        return p

    # -------------------------------------------------------------
    # DOCUMENT COVER / TITLE HEADER
    # -------------------------------------------------------------
    title_p = doc.add_paragraph()
    title_p.paragraph_format.space_before = Pt(10)
    title_p.paragraph_format.space_after = Pt(4)
    run_app = title_p.add_run("ONLYGIGZ PLATFORM ARCHITECTURE & INTEGRATION SPECIFICATION")
    run_app.font.name = "Segoe UI"
    run_app.font.size = Pt(10)
    run_app.font.bold = True
    run_app.font.color.rgb = COLOR_SECONDARY

    h_main = doc.add_paragraph()
    h_main.paragraph_format.space_before = Pt(2)
    h_main.paragraph_format.space_after = Pt(8)
    r_main = h_main.add_run("Web Frontend Integration & Backend System Reference Guide")
    r_main.font.name = "Segoe UI"
    r_main.font.size = Pt(22)
    r_main.font.bold = True
    r_main.font.color.rgb = COLOR_PRIMARY

    # Metadata Card Table
    meta_table = doc.add_table(rows=4, cols=2)
    meta_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    meta_data = [
        ("Target System:", "OnlyGigz Web Client (Next.js / React / Vue)"),
        ("Backend Services:", "FastAPI REST API, Firebase Firestore, Cloud Storage, Stripe Connect"),
        ("Live API Production URL:", "https://api.onlygigz.app"),
        ("Firebase Project ID:", "onlygigz-33557 (Region: us-central1)")
    ]
    for idx, (label, val) in enumerate(meta_data):
        row = meta_table.rows[idx]
        c0, c1 = row.cells[0], row.cells[1]
        c0.width = Inches(2.0)
        c1.width = Inches(4.5)
        set_cell_background(c0, "F1F5F9")
        set_cell_background(c1, "F8FAFC")
        set_cell_margins(c0, top=60, bottom=60, left=100, right=100)
        set_cell_margins(c1, top=60, bottom=60, left=100, right=100)
        
        p0 = c0.paragraphs[0]
        p0.paragraph_format.space_before = Pt(0); p0.paragraph_format.space_after = Pt(0)
        r0 = p0.add_run(label)
        r0.bold = True; r0.font.name = "Segoe UI"; r0.font.size = Pt(9.5); r0.font.color.rgb = COLOR_PRIMARY
        
        p1 = c1.paragraphs[0]
        p1.paragraph_format.space_before = Pt(0); p1.paragraph_format.space_after = Pt(0)
        r1 = p1.add_run(val)
        r1.font.name = "Segoe UI"; r1.font.size = Pt(9.5); r1.font.color.rgb = COLOR_TEXT

    doc.add_paragraph().paragraph_format.space_after = Pt(12)

    # -------------------------------------------------------------
    # SECTION 1: SYSTEM OVERVIEW & ARCHITECTURE
    # -------------------------------------------------------------
    add_h1("1. Executive Summary & Unified Platform Architecture")
    add_body(
        "The OnlyGigz platform operates as a cohesive, multi-client ecosystem. All platforms—including the Musician Flutter Mobile App, the Organizer Flutter Mobile App, the Admin Dashboard, and any external Web Applications—share a single unified backend foundation. There are no separate databases or disconnected silos. Every booking, gig post, message, payment, or profile update created on the web frontend is instantly synchronized across all mobile and administrative applications in real time."
    )

    add_body(
        "The core backend is structured across four primary pillars:",
        bold_prefix="Core Architecture Pillars: "
    )
    add_bullet("FastAPI REST Engine (Python 3.14): High-performance asynchronous microservice orchestrating gig feeds, application vetting, PDF digital contract generation, Stripe Escrow deposits/releases, user authentication verification, and administrative controls.", "1. REST API: ")
    add_bullet("Firebase Firestore (NoSQL): Real-time document database housing user profiles (Musicians, Organizers), gig metadata, in-app notification records, and sub-collection live messaging streams.", "2. Cloud Database: ")
    add_bullet("Firebase Cloud Storage: Secure object storage for musician portfolio assets (audio recordings, performance videos, stage photos), organizer venue documentation, and chat attachments.", "3. Media Assets: ")
    add_bullet("Stripe Connect (Escrow Engine): Regulated payment rail holding organizer funds safely in escrow upon booking confirmation and disbursing funds to musicians' connected Stripe Express accounts upon gig fulfillment.", "4. Financial Rail: ")

    add_callout_box(
        "Crucial Integration Rule: Your web application should interact with Firebase directly via the official Firebase Web SDK (v10+ modular or v9 compat) for Authentication, real-time message streams, and Firestore queries, while delegating sensitive operations (Escrow deposits, contract signing, payments, application state machines, and PDF generation) to the FastAPI endpoints.",
        title="Architecture Principle",
        box_type="info"
    )

    # -------------------------------------------------------------
    # SECTION 2: FIREBASE WEB APPLICATION SETUP & CONSOLE WALKTHROUGH
    # -------------------------------------------------------------
    add_h1("2. Firebase Web Setup & Console Configuration")
    add_body(
        "To connect your custom web application to the OnlyGigz Firebase infrastructure, follow the step-by-step procedure below. You may either register a new Web App under our existing Firebase project or directly utilize our pre-registered production web credentials."
    )

    add_h2("2.1 Navigating the Firebase Console & Registering a Web App")
    add_body("1. Access the Google Firebase Console at https://console.firebase.google.com/ with authorized access to project: onlygigz-33557.")
    add_body("2. Click on the Gear Icon (Project Settings) in the top left navigation menu and choose Project Settings.")
    add_body("3. Scroll down to the 'Your apps' section. If you wish to register a separate web instance for staging or production, click 'Add app' and select the Web icon (</>).")
    add_body("4. Enter an App nickname (for example: 'OnlyGigz Web Client') and click 'Register app'.")
    add_body("5. You will receive the Firebase configuration object containing apiKey, authDomain, projectId, storageBucket, messagingSenderId, and appId.")

    add_h2("2.2 Pre-Configured Web SDK Credentials")
    add_body(
        "You can directly incorporate the following verified web configuration into your environment files without requiring additional console registration:"
    )

    web_config_code = """// src/lib/firebaseConfig.ts
import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

export const firebaseConfig = {
  apiKey: "AIzaSyChynuewEnIYF376H9BDQr87BMtBmZmgjQ",
  authDomain: "onlygigz-33557.firebaseapp.com",
  projectId: "onlygigz-33557",
  storageBucket: "onlygigz-33557.firebasestorage.app",
  messagingSenderId: "941385767816",
  appId: "1:941385767816:web:cb0d9a49949215ad42383d"
};

// Singleton pattern to prevent re-initialization during hot reloading (Next.js / React)
export const app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);"""
    add_code_block(web_config_code)

    add_h2("2.3 Configuring Authorized Web Domains")
    add_body(
        "Firebase Authentication enforces domain restrictions to safeguard API keys against unauthorized domain origin abuse. Before running your web client in development or deploying to production, ensure your hosting domain is explicitly whitelisted:"
    )
    add_bullet("1. In Firebase Console, open Authentication from the left sidebar and select the Settings tab.")
    add_bullet("2. Scroll to Authorized domains.")
    add_bullet("3. Click 'Add domain' and append all applicable development and production URLs:")
    add_bullet("localhost (default for local development)")
    add_bullet("127.0.0.1 (local fallback)")
    add_bullet("app.onlygigz.app (official production domain)")
    add_bullet("<your-deployment-subdomain>.vercel.app or netlify.app (for preview/staging builds)")

    add_callout_box(
        "If a domain is not added to the Authorized Domains list, Firebase Authentication will throw the error: 'auth/unauthorized-domain' when attempting email link, phone, or third-party OAuth sign-ins.",
        title="Warning: Unauthorized Domain Error",
        box_type="warning"
    )

    # -------------------------------------------------------------
    # SECTION 3: FIREBASE SECURITY RULES & MANDATORY MODIFICATIONS
    # -------------------------------------------------------------
    add_h1("3. Firebase Security Rules & Necessary Adaptations")
    add_body(
        "Security rules are the primary defense barrier protecting user data in Cloud Firestore and Cloud Storage. Because the mobile apps and web frontend share the identical database, the security rules must accommodate both authenticated workflows and public web exploration."
    )

    add_h2("3.1 Firestore Security Rules Analysis (firestore.rules)")
    add_body(
        "The active production Firestore security rules enforce role-based access control (RBAC). Here is how the rules interact with your web application:"
    )

    rules_table = doc.add_table(rows=7, cols=3)
    rules_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table_headers = ["Collection Path", "Security Permission", "Integration Notes for Web Client"]
    for i, h in enumerate(table_headers):
        cell = rules_table.rows[0].cells[i]
        set_cell_background(cell, "182B49")
        set_cell_margins(cell, top=100, bottom=100, left=120, right=120)
        p = cell.paragraphs[0]
        r = p.add_run(h)
        r.bold = True; r.font.name = "Segoe UI"; r.font.size = Pt(9.5); r.font.color.rgb = RGBColor(255, 255, 255)

    rules_content = [
        ("/musicians/{userId}", "read: isSignedIn();\nupdate: isOwner(userId)", "Musician profiles require active sign-in to view. Updates restricted to profile owner."),
        ("/organizers/{userId}", "read: isSignedIn();\nupdate: isOwner(userId)", "Organizer profiles require active sign-in. Updates restricted to profile owner."),
        ("/gigs/{gigId}", "read: isSignedIn();\ncreate/update: isSignedIn()", "Currently requires authentication. See Section 3.2 for public feed modification."),
        ("/chats/{chatId}/messages", "read/write: isSignedIn()", "Enables real-time conversation synchronization between organizer and musician."),
        ("/support_chats/{userId}/messages", "read/write: isSignedIn()", "Real-time support ticket conversation with administrative staff."),
        ("/policies/{policyId}", "read: true;\nwrite: isSignedIn()", "Public legal documents (Terms of Service, Privacy Policy, DMCA, About Us).")
    ]

    for idx, (col_path, perm, notes) in enumerate(rules_content):
        row = rules_table.rows[idx + 1]
        c0, c1, c2 = row.cells[0], row.cells[1], row.cells[2]
        c0.width = Inches(2.0); c1.width = Inches(1.8); c2.width = Inches(2.7)
        bg = "F8FAFC" if idx % 2 == 0 else "FFFFFF"
        for c in (c0, c1, c2):
            set_cell_background(c, bg)
            set_cell_margins(c, top=80, bottom=80, left=100, right=100)
        
        p0 = c0.paragraphs[0]; r0 = p0.add_run(col_path); r0.font.name = "Consolas"; r0.font.size = Pt(8.5)
        p1 = c1.paragraphs[0]; r1 = p1.add_run(perm); r1.font.name = "Segoe UI"; r1.font.size = Pt(8.5)
        p2 = c2.paragraphs[0]; r2 = p2.add_run(notes); r2.font.name = "Segoe UI"; r2.font.size = Pt(8.5)

    add_h2("3.2 Mandatory Rules Modification for Public Web Gig Browsing")
    add_body(
        "In mobile applications, users typically create an account before browsing. However, on the web, search engine crawlers (SEO) and prospective users need to view open gigs on a public landing page before signing up."
    )
    add_body(
        "To enable unauthenticated gig browsing on the web frontend without compromising write security, the gig rules in firestore.rules must be modified as follows:"
    )

    code_diff = """// Current Production Rule (Requires Sign-In):
match /gigs/{gigId} {
  allow read: if isSignedIn();
  allow create, update: if isSignedIn();
  allow delete: if isSignedIn() && (resource.data.organizerId == request.auth.uid || request.auth.token.admin == true);
}

// Recommended Web-Compatible Rule (Allows Public Read for Active Gigs):
match /gigs/{gigId} {
  // Allow unauthenticated visitors to read open gigs for web landing pages
  allow read: if true;
  allow create, update: if isSignedIn();
  allow delete: if isSignedIn() && (resource.data.organizerId == request.auth.uid || request.auth.token.admin == true);
}"""
    add_code_block(code_diff)

    add_h2("3.3 Cloud Storage Security Rules (storage.rules)")
    add_body(
        "Firebase Storage houses all rich binary assets. Files are organized into distinct directory namespaces:"
    )
    add_bullet("/profile_images/{userId}/** - User avatar photos.")
    add_bullet("/portfolios/{userId}/** - Musician mp3 audio tracks, performance videos, and stage photography.")
    add_bullet("/chat_attachments/{chatId}/** - Media, invoices, and contracts exchanged in messaging.")
    add_bullet("/gigs/{gigId}/** - Event venue flyers and organizer gig attachments.")
    add_body(
        "Existing rule: allow read, write: if isSignedIn(); is enforced across all storage buckets. If public portfolio playback is required on the web for unauthenticated visitors, update match /portfolios/{allPaths=**} to allow read: if true;."
    )

    # -------------------------------------------------------------
    # SECTION 4: FASTAPI BACKEND API REFERENCE & INTERACTIVE DOCS
    # -------------------------------------------------------------
    add_h1("4. FastAPI Backend Architecture & Interactive Documentation")
    add_body(
        "The OnlyGigz API server is built with modern FastAPI (Python 3.14) delivering asynchronous endpoints, automated Pydantic schema validation, and instant Swagger UI generation."
    )

    add_h2("4.1 Server Environments & Documentation Endpoints")
    
    server_tbl = doc.add_table(rows=3, cols=3)
    server_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    h_server = ["Environment", "Base URL", "Live Interactive Documentation"]
    for i, h in enumerate(h_server):
        cell = server_tbl.rows[0].cells[i]
        set_cell_background(cell, "182B49")
        set_cell_margins(cell, top=80, bottom=80, left=100, right=100)
        p = cell.paragraphs[0]; r = p.add_run(h); r.bold = True; r.font.color.rgb = RGBColor(255, 255, 255); r.font.size = Pt(9.5)

    s_data = [
        ("Production", "https://api.onlygigz.app", "Swagger: https://api.onlygigz.app/docs\nReDoc: https://api.onlygigz.app/redoc\nSchema: https://api.onlygigz.app/openapi.json"),
        ("Local Development", "http://localhost:8000", "Swagger: http://localhost:8000/docs\nReDoc: http://localhost:8000/redoc\nSchema: http://localhost:8000/openapi.json")
    ]
    for idx, (env, url, doc_links) in enumerate(s_data):
        row = server_tbl.rows[idx + 1]
        c0, c1, c2 = row.cells[0], row.cells[1], row.cells[2]
        c0.width = Inches(1.8); c1.width = Inches(2.2); c2.width = Inches(2.5)
        for c in (c0, c1, c2):
            set_cell_background(c, "F8FAFC" if idx % 2 == 0 else "FFFFFF")
            set_cell_margins(c, top=80, bottom=80, left=100, right=100)
        c0.paragraphs[0].add_run(env).font.bold = True
        c1.paragraphs[0].add_run(url).font.name = "Consolas"
        c2.paragraphs[0].add_run(doc_links).font.size = Pt(8.5)

    add_h2("4.2 CORS Configuration & Domain Whitelisting")
    add_body(
        "To prevent Cross-Origin Resource Sharing (CORS) rejections when your frontend performs browser-based fetch() or axios requests to the backend, ensure your frontend origin is registered in backend/main.py."
    )
    add_body("Currently authorized production origins:")
    add_bullet("https://admin.onlygigz.app")
    add_bullet("https://onlygigz.app and https://www.onlygigz.app")
    add_bullet("http://localhost:3000 and http://127.0.0.1:3000 (React / Next.js local servers)")
    add_bullet("http://localhost:8000 (FastAPI local Swagger UI)")
    add_bullet("Wildcard regex: https://.*onlygigz\\.app")
    add_body("Note: If deploying your frontend to Vercel, Netlify, or AWS Amplify under a temporary subdomain, notify the backend engineering team to append your origin domain to the CORS whitelist.")

    # -------------------------------------------------------------
    # SECTION 5: EXHAUSTIVE REST API ENDPOINT REFERENCE
    # -------------------------------------------------------------
    add_h1("5. Exhaustive REST API Endpoint Reference")
    add_body(
        "The following section provides the comprehensive endpoint catalog across all backend modules, including payload parameters, query options, and sample JSON payloads."
    )

    # 5.1 Authentication
    add_h2("5.1 Authentication Module (/auth)")
    add_body("Handles unified role-based authentication, user profile hydration, email OTP verification, and multi-factor authentication (2FA).")

    auth_table = doc.add_table(rows=7, cols=3)
    auth_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, h in enumerate(["HTTP Method & Path", "Description & Roles", "Payload / Parameters"]):
        cell = auth_table.rows[0].cells[i]
        set_cell_background(cell, "182B49")
        set_cell_margins(cell, top=80, bottom=80, left=100, right=100)
        p = cell.paragraphs[0]; r = p.add_run(h); r.bold = True; r.font.color.rgb = RGBColor(255, 255, 255); r.font.size = Pt(9.5)

    auth_endpoints = [
        ("POST /auth/signin", "Verifies credentials and returns user role (musician / organizer / admin).", "{\n  \"email\": \"user@example.com\",\n  \"password\": \"Secret123!\"\n}"),
        ("POST /auth/signup", "Registers an event organizer account and provisions Firestore profile.", "{\n  \"email\": \"org@club.com\",\n  \"password\": \"Pass123!\",\n  \"fullName\": \"Sarah Connor\",\n  \"organizationName\": \"Blue Note Club\"\n}"),
        ("POST /auth/signup/musician", "Registers a musician with instrument, genre, and rate specs.", "{\n  \"email\": \"jazz@trio.com\",\n  \"password\": \"Pass123!\",\n  \"fullName\": \"Miles Davis\",\n  \"stageName\": \"Miles Quartet\",\n  \"genre\": \"Jazz\",\n  \"hourlyRate\": 175.0\n}"),
        ("GET /auth/profile/{uid}", "Fetches unified profile document from Firestore.", "URL Parameter: uid (Firebase Auth UID)"),
        ("POST /auth/profile/update", "Updates biography, location, phone number, and avatar URL.", "{\n  \"uid\": \"...\",\n  \"fullName\": \"...\",\n  \"bio\": \"Award-winning jazz trumpeter\",\n  \"city\": \"Austin\",\n  \"state\": \"TX\"\n}"),
        ("POST /auth/send-email-otp", "Sends 6-digit confirmation code for password resets & verifications.", "{\n  \"email\": \"user@example.com\"\n}")
    ]
    for idx, (path, desc, payload) in enumerate(auth_endpoints):
        row = auth_table.rows[idx + 1]
        c0, c1, c2 = row.cells[0], row.cells[1], row.cells[2]
        c0.width = Inches(2.2); c1.width = Inches(2.3); c2.width = Inches(2.0)
        for c in (c0, c1, c2):
            set_cell_background(c, "F8FAFC" if idx % 2 == 0 else "FFFFFF")
            set_cell_margins(c, top=60, bottom=60, left=80, right=80)
        c0.paragraphs[0].add_run(path).font.name = "Consolas"; c0.paragraphs[0].runs[0].font.size = Pt(8.5); c0.paragraphs[0].runs[0].bold = True
        c1.paragraphs[0].add_run(desc).font.name = "Segoe UI"; c1.paragraphs[0].runs[0].font.size = Pt(8.5)
        c2.paragraphs[0].add_run(payload).font.name = "Consolas"; c2.paragraphs[0].runs[0].font.size = Pt(7.5)

    # 5.2 Gigs
    add_h2("5.2 Gigs & Opportunities Module (/gigs)")
    add_body("Powers gig discovery, advanced filtering, gig creation by organizers, and application submissions by musicians.")
    add_bullet("GET /gigs/list - Query Parameters: status (open/booked/completed), organizer_id, search_query, genre, min_budget, max_budget, city, state. Returns array of Gig objects.")
    add_bullet("GET /gigs/{gig_id} - Fetches complete gig details including organizer contact, venue specs, and timing.")
    add_bullet("POST /gigs/create - Organizer creates a new gig listing.")
    add_bullet("POST /gigs/apply - Musician applies for a gig, supplying quote amount, cover message, and portfolio attachments.")
    add_bullet("GET /gigs/applications/list - Filter applications by gig_id (organizer view) or musician_id (musician view).")
    add_bullet("PATCH /gigs/{gig_id}/status - Update gig state (e.g. 'open' -> 'booked').")

    add_body("Gig Creation Sample Payload:", bold_prefix="POST /gigs/create Payload: ")
    gig_payload = """{
  \"organizerId\": \"usr_org_88921\",
  \"title\": \"Downtown Rooftop Jazz Quartet\",
  \"description\": \"Looking for a 4-piece jazz band for upscale cocktail reception. Must play classic bebop and smooth jazz standards.\",
  \"venue\": \"The Skylight Lounge\",
  \"location\": \"Austin, TX\",
  \"address\": \"400 Congress Ave, Austin, TX 78701\",
  \"date\": \"2026-10-15\",
  \"startTime\": \"19:00\",
  \"endTime\": \"22:00\",
  \"genre\": \"Jazz\",
  \"compensation\": 1200.00,
  \"isHighBudget\": true,
  \"equipmentProvided\": [\"Full PA System\", \"Mapex Drum Kit\", \"Microphones\"],
  \"requirements\": [\"21+ Only\", \"Cocktail Attire Required\"]
}"""
    add_code_block(gig_payload)

    # 5.3 Bookings & Contracts
    add_h2("5.3 Bookings & Digital Contracts Module (/bookings)")
    add_body(
        "Governs the formal legal and transactional agreement between organizer and talent once an application is approved."
    )
    add_bullet("POST /bookings/confirm - Transforms an approved application into an active Booking. Generates digital contract terms.")
    add_bullet("GET /bookings/list - Query bookings by musician_id or organizer_id. Includes payment status and date.")
    add_bullet("GET /bookings/{booking_id} - Retrieves full booking dossier, including escrow funding status and signature states.")
    add_bullet("POST /bookings/{booking_id}/musician-sign - Musician records digital signature. Payload: {\"signatureUrl\": \"...\"}.")
    add_bullet("GET /bookings/{booking_id}/contract/pdf - Dynamic ReportLab generation returning the official OnlyGigz legal contract PDF document.")

    # 5.4 Messaging
    add_h2("5.4 Real-Time Chat & Direct Messaging Module (/chat)")
    add_body(
        "Chat can be consumed via REST endpoints or directly subscribed to in real time via Firestore client SDK listeners."
    )
    add_bullet("POST /chat/get-or-create - Takes participantIds: [\"organizerUid\", \"musicianUid\"], gigId (optional). Returns existing or newly initialized chatId.")
    add_bullet("POST /chat/send-message - Dispatches a message. Dispatches real-time in-app notification to the recipient.")
    add_bullet("GET /chat/unread-count/{user_id} - Aggregate unread message counter for notification badges.")
    add_bullet("POST /chat/mark-read/{chat_id}/{user_id} - Acknowledges all messages in a conversation as read.")

    add_body("Real-Time Firestore Listener Implementation (Client-side):", bold_prefix="Firestore Realtime Snapshot: ")
    chat_listener_code = """// Real-time message streaming on web using Firebase Modular SDK
import { collection, query, orderBy, onSnapshot } from "firebase/firestore";
import { db } from "@/lib/firebaseConfig";

export function subscribeToChatMessages(chatId: string, callback: (messages: any[]) => void) {
  const messagesRef = collection(db, "chats", chatId, "messages");
  const q = query(messagesRef, orderBy("timestamp", "asc"));

  return onSnapshot(q, (snapshot) => {
    const messages = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    callback(messages);
  });
}"""
    add_code_block(chat_listener_code)

    # 5.5 Support & Tickets
    add_h2("5.5 Support Desk & System Notifications (/support & /notifications)")
    add_bullet("GET /support/chats/{user_id}/messages - Retrieves user support inquiry history.")
    add_bullet("POST /support/chats/{user_id}/messages - Dispatches customer support ticket message to admin dashboard.")
    add_bullet("GET /notifications/user/{user_id} - Retrieves system notifications (gig approvals, booking payouts, chat alerts).")
    add_bullet("PATCH /notifications/{notification_id}/read - Sets isRead = true for an individual notification.")

    # -------------------------------------------------------------
    # SECTION 6: STRIPE CONNECT & ESCROW ARCHITECTURE FOR WEB
    # -------------------------------------------------------------
    add_h1("6. Stripe Connect & Escrow Architecture for Web")
    add_body(
        "OnlyGigz utilizes Stripe Connect with an Escrow Architecture. Organizers pay into a secure escrow account upon booking confirmation. Funds are held safely until the gig is successfully performed, at which point the payout is released to the musician's connected Stripe Express account minus platform commission."
    )

    add_h2("6.1 Stripe Credentials")
    add_bullet("Stripe Test Publishable Key: pk_test_51TWa16C4PTfB0I2XPl7KWaEgeyQOWAKXvicPoQoF3GxAmIFBYMeKI2Y9AsRNvdny7dzVJ7Inj9W15zVP7CfyKDPF003AgOz7G8")
    add_bullet("Stripe Connect Mode: Express Accounts for Musicians, Direct Charges & Escrow Holds for Organizers.")

    add_h2("6.2 Web Card Saving & Checkout (Stripe Elements)")
    add_body(
        "While mobile uses native bottom sheets, web clients must use @stripe/stripe-js and @stripe/react-stripe-js. The flow operates as follows:"
    )
    add_bullet("Step 1: Organizer initiates checkout. Frontend calls POST /payments/organizer/setup-intent with { \"organizerId\": uid }.")
    add_bullet("Step 2: Backend returns clientSecret (e.g. seti_1P..._secret_...).")
    add_bullet("Step 3: Frontend mounts Stripe <PaymentElement /> inside an <Elements stripe={stripePromise} options={{ clientSecret }}> provider.")
    add_bullet("Step 4: User enters card details and submits. Frontend executes stripe.confirmSetup().")
    add_bullet("Step 5: Frontend sends the resulting paymentMethodId to POST /payments/organizer/save-payment-method.")
    add_bullet("Step 6: When booking is confirmed, call POST /payments/booking/{booking_id}/deposit to capture funds into Escrow.")

    add_h2("6.3 Musician Stripe Express Onboarding (Payout Bank Setup)")
    add_body(
        "To receive earnings, musicians must onboard via Stripe Express. The web frontend implements this with a simple redirect:"
    )
    stripe_onboard_code = """// Initiating Musician Payout Setup on Web
async function handleMusicianStripeConnect(musicianUid: string) {
  const response = await fetch("https://api.onlygigz.app/payments/musician/onboard", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      musicianId: musicianUid,
      refreshUrl: `${window.location.origin}/wallet?status=refresh`,
      returnUrl: `${window.location.origin}/wallet?status=success`
    })
  });
  
  const data = await response.json();
  if (data.onboardingUrl) {
    // Redirect musician to Stripe hosted KYC/Banking page
    window.location.href = data.onboardingUrl;
  }
}"""
    add_code_block(stripe_onboard_code)

    # -------------------------------------------------------------
    # SECTION 7: PRODUCTION LAUNCH & VERIFICATION CHECKLIST
    # -------------------------------------------------------------
    add_h1("7. Web Client Production Launch Checklist")
    add_body(
        "Before deploying the web application to production, complete the following quality assurance verification points:"
    )

    checklist_items = [
        ("Firebase Configuration", "Firebase Web SDK initialized with onlygigz-33557 configuration. Tested on clean browser profile."),
        ("Authorized Domains", "Production domain (e.g. app.onlygigz.app) added to Firebase Auth -> Settings -> Authorized Domains."),
        ("FastAPI CORS Whitelist", "Frontend production URL submitted to backend team and whitelisted in backend/main.py."),
        ("Public Gig Browsing Rules", "firestore.rules verified to allow public read (allow read: if true;) if SEO gig feed is required."),
        ("Stripe Publishable Key", "Frontend configured with official OnlyGigz test publishable key (or live key upon production switch)."),
        ("Storage Upload Restrictions", "Media uploads to /portfolios/ and /profile_images/ validated for maximum file sizes (< 50MB)."),
        ("Error Boundary & Token Expiry", "Axios/Fetch client configured with 401 interception to trigger Firebase auth.currentUser.getIdToken(true).")
    ]

    check_tbl = doc.add_table(rows=len(checklist_items) + 1, cols=2)
    check_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, h in enumerate(["Verification Task", "Validation Criteria"]):
        cell = check_tbl.rows[0].cells[i]
        set_cell_background(cell, "182B49")
        set_cell_margins(cell, top=80, bottom=80, left=100, right=100)
        p = cell.paragraphs[0]; r = p.add_run(h); r.bold = True; r.font.color.rgb = RGBColor(255, 255, 255); r.font.size = Pt(9.5)

    for idx, (task, crit) in enumerate(checklist_items):
        row = check_tbl.rows[idx + 1]
        c0, c1 = row.cells[0], row.cells[1]
        c0.width = Inches(2.2); c1.width = Inches(4.3)
        for c in (c0, c1):
            set_cell_background(c, "F8FAFC" if idx % 2 == 0 else "FFFFFF")
            set_cell_margins(c, top=60, bottom=60, left=80, right=80)
        c0.paragraphs[0].add_run(task).font.bold = True; c0.paragraphs[0].runs[0].font.size = Pt(9)
        c1.paragraphs[0].add_run(crit).font.size = Pt(9)

    doc.add_paragraph().paragraph_format.space_after = Pt(16)

    # Sign-off box
    add_callout_box(
        "Document Prepared by OnlyGigz Engineering Team.\nFor API inquiries, backend support, or custom domain CORS authorization, contact: tech@onlygigz.app or refer to https://api.onlygigz.app/docs.",
        title="Engineering Sign-Off & Support",
        box_type="success"
    )

    output_path = "/Users/muhammadali3000/development/onlygigz/OnlyGigz_Web_Integration_and_Backend_Architecture_Guide.docx"
    doc.save(output_path)
    print(f"Document successfully saved to {output_path}")

if __name__ == "__main__":
    create_document()
