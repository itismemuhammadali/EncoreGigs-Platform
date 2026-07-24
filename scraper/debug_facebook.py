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
cookies = raw_cookies

proxy = {"server": "http://gate.decodo.com:10001"}

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
    context.add_cookies(cookies)
    page = context.new_page()
    page.add_init_script(STEALTH_JS)

    search_url = "https://www.facebook.com/search/groups/?q=austin%20musician%20gigs%20wanted"
    page.goto(search_url, wait_until="domcontentloaded", timeout=30000)
    time.sleep(10)

    page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
    time.sleep(5)

    print(f"URL: {page.url}")
    print(f"Title: {page.title()}")

    if "login" in page.url.lower():
        print("REDIRECTED TO LOGIN!")
        browser.close()
        sys.exit(1)

    # Dump all text to find group names
    body = page.inner_text("body")
    lines = [l.strip() for l in body.split("\n") if l.strip() and len(l.strip()) > 5]
    print(f"\nBody text lines: {len(lines)}")
    for line in lines[:50]:
        print(f"  {line[:120]}")

    browser.close()
