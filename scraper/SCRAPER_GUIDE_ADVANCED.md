# Advanced Setup Guide: Facebook API & GigSalad Scraping

This guide provides step-by-step instructions for implementing "Pro-level" data collection for Facebook and GigSalad.

---

## Part 1: Facebook Official API Setup (For Pages)

While the Groups API is deprecated, the **Pages API** is still the most stable way to get events from venues and organizers who have a public Facebook Page.

### Step-by-Step API Key Process:
1.  **Create a Meta Developer Account:**
    - Go to [developers.facebook.com](https://developers.facebook.com/) and register.
2.  **Create a New App:**
    - Select "Other" -> "Business" as the app type.
    - Give it a name like `OnlyGigz-Aggregator`.
3.  **Add Products:**
    - In the dashboard, add the **"Graph API"** product.
4.  **Obtain a User Access Token:**
    - Open the **Graph API Explorer** tool.
    - Select your App.
    - Add the following permissions: `pages_read_engagement`, `pages_show_list`.
    - Click "Generate Token".
5.  **Convert to a Long-Lived Token (Essential):**
    - Standard tokens expire in 1-2 hours. You must exchange them for a "Long-Lived" token (60 days) or a "Permanent" Page Token using the Meta "Access Token Tool".
6.  **Requirements for Production:**
    - **Business Verification:** You must have a registered business and provide legal documents to Meta.
    - **App Review:** You must record a screencast of how you use the data and submit it to Meta for approval.

---

## Part 2: GigSalad & Facebook Groups (The Scraping Path)

Because GigSalad and FB Groups are protected by Cloudflare/Bot-detection, you need **Residential Proxies** or a **Scraping API**.

### 1. What do we need?
To make the current Python scraper work with 100% success, you need a subscription to a service like **ZenRows**, **Bright Data**, or **ScraperAPI**.

### 2. Step-by-Step Implementation (using ZenRows as an example):

1.  **Get an API Key:**
    - Sign up at [ZenRows.com](https://www.zenrows.com/).
    - Copy your `API_KEY`.
2.  **What to buy:**
    - You need a plan that supports **"JS Rendering"** and **"Premium Proxies"**.
3.  **How to update the Scraper code:**
    Instead of complex Playwright code, we simplify it to a standard request through their "smart" gateway.

**Modified `gigsalad_scraper.py` logic:**
```python
import requests

def scrape(self):
    params = {
        'url': self.base_url,
        'apikey': 'YOUR_ZENROWS_API_KEY',
        'js_render': 'true',      # Bypasses Cloudflare
        'premium_proxy': 'true',  # Uses Residential IPs
    }
    response = requests.get('https://api.zenrows.com/v1/', params=params)
    # Now simply parse the HTML like we do for Craigslist
    soup = BeautifulSoup(response.text, 'html.parser')
```

---

## Part 3: Summary of Requirements

| Platform | What we need from Client | Technical Requirement |
| :--- | :--- | :--- |
| **Facebook Pages** | App Approval from Meta | Official Meta Business Account |
| **Facebook Groups** | Burner FB Account | Session Cookie Extraction |
| **GigSalad** | Scraping Service Subscription | Residential Proxy API Key (e.g., ZenRows) |

### Immediate Action Items:
1.  **Decide on a Scraping Provider:** I recommend ZenRows or ScraperAPI for their simplicity.
2.  **Setup Meta Business Suite:** If you want official data from Pages.
3.  **Create a "Burner" Facebook Account:** For group scraping to avoid risking your personal account.
