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

proxy = {"server": "http://gate.decodo.com:10002"}

STEALTH_JS = """
Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
window.chrome = { runtime: {}, app: { isInstalled: false } };
"""

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

    url = "https://www.facebook.com/groups/AustinMusicians/"
    page.goto(url, wait_until="domcontentloaded", timeout=30000)
    time.sleep(8)

    # Dismiss cookie consent
    try:
        decline = page.query_selector("button:has-text('Decline optional cookies')")
        if decline:
            decline.click()
            print("Clicked: Decline optional cookies")
            time.sleep(2)
    except:
        pass

    try:
        accept = page.query_selector("button:has-text('Allow')")
        if accept:
            accept.click()
            print("Clicked: Allow cookies")
            time.sleep(2)
    except:
        pass

    # Scroll multiple times to load posts
    for i in range(5):
        page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
        time.sleep(3)
        print(f"Scroll {i+1}/5")

    print(f"\nTitle: {page.title()}")
    print(f"URL: {page.url}")

    body = page.inner_text("body")
    lines = [l.strip() for l in body.split("\n") if l.strip() and len(l.strip()) > 20]

    gig_words = ["looking for", "need a", "need a ", "hiring", "gig", "wanted", "seeking", "available", "bassist", "guitarist", "drummer", "vocalist", "singer", "band", "wedding", "party", "event", "pay", "rate", "playing", "open mic", "audition", "rehearsal", "session", "cover band"]

    print(f"\nTotal lines: {len(lines)}")
    print(f"\n--- GIG POSTS ---")
    found = 0
    for line in lines:
        if any(w in line.lower() for w in gig_words) and len(line) > 30:
            print(f"\n  {line[:200]}")
            found += 1
            if found >= 15:
                break

    if found == 0:
        print("\n--- ALL POSTS (first 20) ---")
        for line in lines[:20]:
            print(f"  {line[:150]}")

    browser.close()
