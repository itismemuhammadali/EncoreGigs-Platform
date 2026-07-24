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

    # Dismiss cookie dialogs
    for sel in [
        "button:has-text('Decline optional cookies')",
        "button:has-text('Allow all cookies')",
        "[data-cookiebanner='accept_button']",
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

    try:
        page.keyboard.press("Escape")
        time.sleep(1)
    except:
        pass

    # Scroll to load posts
    for i in range(6):
        page.evaluate("window.scrollBy(0, 1000)")
        time.sleep(3)

    # Extract from role='article' elements
    articles = page.query_selector_all("[role='article']")
    print(f"\nFound {len(articles)} article elements")

    for i, article in enumerate(articles[:10]):
        try:
            text = article.inner_text()
            if len(text) > 30:
                print(f"\n=== POST {i+1} ===")
                print(text[:300])
        except:
            continue

    # Also try data-ad-rendering-role
    story_msgs = page.query_selector_all("[data-ad-rendering-role='story_message']")
    print(f"\nFound {len(story_msgs)} story_message elements")
    for i, sm in enumerate(story_msgs[:5]):
        try:
            text = sm.inner_text()
            if len(text) > 30:
                print(f"\n=== STORY {i+1} ===")
                print(text[:300])
        except:
            continue

    browser.close()
