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

    page.goto("https://www.gigsalad.com", wait_until="commit", timeout=30000)
    time.sleep(5)
    print(f"HOMEPAGE: {page.title()} | {page.url}")

    links = page.query_selector_all("a[href]")
    gig_links = []
    for link in links:
        href = link.get_attribute("href")
        text = link.inner_text().strip()[:50]
        if href and ("gig" in href.lower() or "browse" in href.lower() or "search" in href.lower() or "find" in href.lower()):
            gig_links.append(f"  {text:30s} -> {href}")
    
    print(f"\nGig-related links found: {len(gig_links)}")
    for gl in gig_links[:20]:
        print(gl)

    browser.close()
