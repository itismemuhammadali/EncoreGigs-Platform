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

urls = [
    "https://www.gigsalad.com/gigs/texas/austin",
    "https://www.gigsalad.com/gigs/austin-texas",
    "https://www.gigsalad.com/browse/gigs/texas/austin",
    "https://www.gigsalad.com/search?q=music&location=austin+tx",
    "https://www.gigsalad.com/gigs?location=austin-tx",
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
    page = context.new_page()
    page.add_init_script(STEALTH_JS)

    for url in urls:
        page.goto(url, wait_until="commit", timeout=20000)
        time.sleep(3)
        title = page.title()
        print(f"{title:40s} | {url}")

    browser.close()
