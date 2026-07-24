import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend", ".env"))

from playwright.sync_api import sync_playwright
import time, json

COOKIES_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "facebook_cookies.json")

with open(COOKIES_FILE) as f:
    cookies = json.load(f)

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

    groups = ["AustinMusicianGigs", "AustinMusicians", "ATXLiveMusic"]

    for group in groups:
        url = f"https://www.facebook.com/groups/{group}/"
        print(f"\n=== {group} ===")
        try:
            page.goto(url, wait_until="domcontentloaded", timeout=30000)
            time.sleep(5)
            title = page.title()
            current_url = page.url
            print(f"Title: {title}")
            print(f"URL: {current_url}")

            if "login" in current_url.lower():
                print("REDIRECTED TO LOGIN - cookies expired!")
                continue

            posts = page.query_selector_all("div[dir='auto']")
            print(f"Post elements: {len(posts)}")

            found = 0
            for post in posts[:20]:
                try:
                    text = post.inner_text().strip()
                    if len(text) > 30:
                        print(f"  POST: {text[:120]}")
                        found += 1
                        if found >= 3:
                            break
                except:
                    continue

        except Exception as e:
            print(f"ERROR: {str(e)[:100]}")

    browser.close()
