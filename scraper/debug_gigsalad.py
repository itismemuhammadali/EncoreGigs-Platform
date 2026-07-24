import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend", ".env"))

from playwright.sync_api import sync_playwright
import time

proxy = {"server": "http://gate.decodo.com:10001"}

STEALTH_JS = """
Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
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
    page = context.new_page()
    page.add_init_script(STEALTH_JS)

    page.goto("https://www.gigsalad.com/book-music?location=austin-tx", wait_until="commit", timeout=30000)
    time.sleep(5)

    title = page.title()
    print(f"PAGE: {title}")

    # Get ALL links on this page
    all_links = page.query_selector_all("a[href]")
    for link in all_links:
        href = link.get_attribute("href") or ""
        text = link.inner_text().strip()[:80]
        if text and ("gig" in href.lower() or "event" in href.lower() or "post" in href.lower() or "hire" in text.lower() or "looking" in text.lower() or "need" in text.lower() or "planner" in text.lower() or "client" in text.lower()):
            print(f"  {text:50s} -> {href}")

    # Also dump page text to find gig listings
    body_text = page.inner_text("body")
    # Look for lines that mention hiring/gigs
    for line in body_text.split("\n"):
        line = line.strip()
        if len(line) > 20 and any(w in line.lower() for w in ["looking for", "need a", "hire", "post a gig", "browse gigs", "event", "planner", "client"]):
            print(f"  TEXT: {line[:120]}")

    browser.close()
