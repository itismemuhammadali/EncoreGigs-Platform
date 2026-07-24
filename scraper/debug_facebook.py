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

    # Try to dismiss all cookie dialogs aggressively
    for sel in [
        "button:has-text('Decline optional cookies')",
        "button:has-text('Decline')",
        "button:has-text('Allow all cookies')",
        "button:has-text('Allow')",
        "[data-cookiebanner='accept_button']",
        "[data-testid='cookie-policy-manage-dialog-accept-button']",
        "button[title='Allow']",
        "button[title='Accept']",
    ]:
        try:
            btn = page.query_selector(sel)
            if btn and btn.is_visible():
                btn.click()
                print(f"Clicked: {sel}")
                time.sleep(2)
                break
        except:
            continue

    # Also try to close any overlays
    try:
        page.keyboard.press("Escape")
        time.sleep(1)
    except:
        pass

    time.sleep(3)

    # Scroll to load content
    for i in range(8):
        page.evaluate("window.scrollBy(0, 800)")
        time.sleep(2)
        print(f"Scroll {i+1}/8")

    print(f"\nTitle: {page.title()}")

    # Get full page HTML and dump it
    content = page.content()
    print(f"HTML length: {len(content)}")

    # Try to find post containers with different selectors
    selectors = [
        "[data-ad-rendering-role='story_message']",
        "[data-ad-preview='message']",
        "div[dir='auto']",
        "[role='article']",
        "span[data-text='true']",
    ]
    for sel in selectors:
        items = page.query_selector_all(sel)
        print(f"Selector '{sel}': {len(items)} elements")

    body = page.inner_text("body")
    lines = [l.strip() for l in body.split("\n") if l.strip() and len(l.strip()) > 20]
    print(f"\nBody lines: {len(lines)}")
    for line in lines[:25]:
        print(f"  {line[:150]}")

    browser.close()
