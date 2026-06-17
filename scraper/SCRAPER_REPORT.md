# OnlyGigz Scraper System Report

This report provides a comprehensive overview of the OnlyGigz scraping system, including its architecture, supported platforms, data models, and operational instructions.

## 1. Overview
The OnlyGigz Scraper is a Python-based modular system designed to aggregate musical gig opportunities from various online platforms. It standardizes diverse data formats into a unified schema and stores them in a Firestore database.

## 2. Architecture
The system follows an Object-Oriented design:
- **BaseScraper (Abstract Class):** The standard interface for all scrapers.
- **ScraperManager:** Orchestrates the execution and database saving.
- **Playwright Integration:** Uses browser automation for platforms with high protection.

## 3. Supported Platforms

| Platform | Status | Method | Details |
| :--- | :--- | :--- | :--- |
| **Craigslist** | **Active** | HTTP + BeautifulSoup | Scrapes the `ggg` category. Updated for the 2024+ static HTML layout. |
| **Eventbrite** | **Active** | HTTP + JSON-LD | High-reliability extraction using embedded schema.org metadata. |
| **Facebook** | **Skeleton** | Pattern Matching | Regex-based contact extraction. Requires browser automation/cookies for live data. |
| **GigSalad** | **Active (Adv.)** | Playwright + Stealth | Uses browser automation with custom JS stealth scripts to mimic human behavior. |

## 4. Data Extraction Details
The scraper fetches:
- **Gig Details:** Title, Description, Budget, Location, Timing, and Source URL.
- **Organizer Info:** Name, Organization Type, and auto-extracted contact info (emails/phones).

## 5. Storage & Database
- **Destination:** Firestore (Local Emulator).
- **Collection:** `scraped_gigs` (Kept separate from the main `gigs` collection for moderation).
- **Duplicate Prevention:** Uses `externalId` to ensure no gig is saved twice.

## 6. How to Run

### Prerequisites
- Python 3.9+
- Firebase Emulator Suite
- **Playwright Browsers:** `python3 -m playwright install chromium`

### Installation
```bash
# From the project root
python3 -m pip install -r scraper/requirements.txt
python3 -m playwright install chromium
```

### Execution
```bash
python3 scraper/main.py
```

## 7. Technical Challenges & Proposed Solutions

### The "Bot Detection" Challenge
Platforms like GigSalad and Facebook use advanced Web Application Firewalls (like Cloudflare) that detect automated browsing. Even with Stealth scripts, data center IP addresses (like the one you are currently using) are often flagged.

### Proposed Solutions for 100% Reliability:

#### 1. Residential Proxy Service (API Keys Needed)
Services like **Bright Data**, **Oxylabs**, or **SmartProxy** provide IP addresses from real home users.
- **Benefit:** Makes the scraper look like a real person browsing from home.
- **Requirement:** A paid API key and updating the scraper to use the proxy string.

#### 2. Specialized Scraping APIs (e.g., ZenRows, ScraperAPI)
These are "all-in-one" solutions where you send the URL to their API, and they return the fully rendered HTML, handling all proxies and CAPTCHAs automatically.
- **Implementation:** We would replace the Playwright logic with a simple `requests.get()` to their endpoint.

#### 3. Facebook Session Cookies
For Facebook specifically, the best way is to use a "Burner" account. We would manually log in once, extract the session cookies, and provide them to the scraper so it doesn't need to log in itself.

## 8. Official API Analysis

### Facebook (Meta) Graph API
Meta provides an official API, but it has significant limitations for scraping:
- **Groups API Deprecated:** As of 2024, Meta removed the ability for third-party apps to read Group posts/events via the API. This means **scraping is the only way** to get data from most Groups.
- **Page API:** If a venue has a "Public Page," we *can* use an official Page Access Token to get their events list. This is much more stable than scraping.
- **Requirement:** Requires "App Review" and "Business Verification" from Meta, which can take weeks.

### GigSalad "API"
GigSalad does **not** have a public developer API.
- **Internal Only:** They use an internal API for their own apps, but it is protected and not open to the public.
- **Partnerships:** Access to their data usually requires a direct business partnership.
- **Verdict:** For an independent aggregator, **Scraping with Residential Proxies** remains the most viable technical path.
