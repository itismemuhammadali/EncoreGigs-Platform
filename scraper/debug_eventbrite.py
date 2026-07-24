import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend", ".env"))

from playwright.sync_api import sync_playwright
from bs4 import BeautifulSoup
import time, json

STEALTH_JS = """
Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
window.chrome = { runtime: {}, app: { isInstalled: false } };
"""

with sync_playwright() as p:
    browser = p.chromium.launch(
        headless=False,
        args=["--disable-blink-features=AutomationControlled", "--no-sandbox"]
    )
    context = browser.new_context(
        viewport={"width": 1920, "height": 1080},
        user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
        locale="en-US",
    )
    page = context.new_page()
    page.add_init_script(STEALTH_JS)

    url = "https://www.eventbrite.com/d/tx--austin/music--events/"
    page.goto(url, wait_until="commit", timeout=30000)
    
    for i in range(6):
        time.sleep(5)
        title = page.title()
        print(f"[{i*5}s] Title: {title}")
        if "moment" not in title.lower() and "challenge" not in title.lower():
            break

    html = page.content()
    print(f"\nHTML length: {len(html)}")

    soup = BeautifulSoup(html, "html.parser")
    scripts = soup.find_all("script", type="application/ld+json")
    print(f"JSON-LD scripts: {len(scripts)}")

    for script in scripts:
        try:
            data = json.loads(script.string)
            t = data.get("@type", "unknown")
            print(f"\nType: {t}")
            if isinstance(data, dict) and t == "ItemList":
                items = [li.get("item") for li in data.get("itemListElement", []) if li.get("item")]
                print(f"Events: {len(items)}")
                for item in items[:5]:
                    print(f"  - {item.get('name', '?')}")
        except Exception as e:
            print(f"Parse error: {e}")

    browser.close()
