import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend", ".env"))

from playwright.sync_api import sync_playwright
import time, json

COOKIES_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "facebook_cookies.json")

with open(COOKIES_FILE) as f:
    raw_cookies = json.load(f)
for c in raw_cookies:
    ss = c.get("sameSite", "Lax")
    if ss not in ("Strict", "Lax", "None"):
        c["sameSite"] = "None" if ss == "no_restriction" else "Lax"

proxy = {"server": "http://gate.decodo.com:10001"}

STEALTH_JS = """
Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
window.chrome = { runtime: {}, app: { isInstalled: false } };
"""

groups = [
    "AustinMusicians",
    "AustinBandmates",
    "ATXLiveMusic",
    "austinmusiciansnetwork",
    "austinmusicclassifieds",
    "austingigboard",
    "centraltexasmusicians",
    "austinmusicianslookingforwork",
    "austinmusicianshoping",
    "LiveMusicAustin",
]

with sync_playwright() as p:
    browser = p.chromium.launch(
        headless=False,
        proxy=proxy,
        args=["--disable-blink-features=AutomationControlled", "--no-sandbox"]
    )
    context = browser.new_context(
        viewport={"width": 1920, "height": 1080},
        user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
        locale="en-US",
    )
    context.add_cookies(raw_cookies)
    page = context.new_page()
    page.add_init_script(STEALTH_JS)

    for group in groups:
        url = f"https://www.facebook.com/groups/{group}/"
        try:
            page.goto(url, wait_until="domcontentloaded", timeout=20000)
            time.sleep(4)
            title = page.title()
            current_url = page.url

            if "login" in current_url.lower():
                print(f"LOGIN REQUIRED: {group}")
                break

            if "sorry" in title.lower() or "not found" in title.lower() or "page" in title.lower():
                print(f"NOT FOUND: {group}")
                continue

            body = page.inner_text("body")[:500]
            gig_words = ["looking for", "need a", "hiring", "gig", "playing", "band", "musician wanted", "seeking"]
            has_gigs = any(w in body.lower() for w in gig_words)
            print(f"{'GIGS' if has_gigs else '----'}: {group:40s} | {title[:60]}")

        except Exception as e:
            print(f"ERROR: {group:40s} | {str(e)[:60]}")

    browser.close()
