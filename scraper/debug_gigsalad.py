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

    urls = [
        "https://www.gigsalad.com/book-music/austin-tx",
        "https://www.gigsalad.com/book-music?location=austin-tx",
        "https://www.gigsalad.com/book-music/austin-texas",
        "https://www.gigsalad.com/opportunities",
        "https://www.gigsalad.com/gig-board",
        "https://www.gigsalad.com/events",
    ]

    for url in urls:
        try:
            page.goto(url, wait_until="commit", timeout=15000)
            time.sleep(3)
            title = page.title()
            links = page.query_selector_all("a[href]")
            gig_links = [l.get_attribute("href") for l in links if l.get_attribute("href") and ("gig" in l.get_attribute("href").lower() or "event" in l.get_attribute("href").lower() or "opportunity" in l.get_attribute("href").lower())]
            print(f"{title:50s} | {url}")
            if gig_links:
                print(f"  -> gig links: {gig_links[:5]}")
        except Exception as e:
            print(f"ERROR: {str(e)[:60]} | {url}")

    browser.close()
