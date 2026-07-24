import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend", ".env"))

from playwright.sync_api import sync_playwright
from playwright_stealth import stealth_sync
import time

proxy = {"server": "http://gate.decodo.com:10001"}

with sync_playwright() as p:
    browser = p.chromium.launch(
        headless=False,
        proxy=proxy,
        args=[
            "--disable-blink-features=AutomationControlled",
            "--no-sandbox",
        ]
    )
    context = browser.new_context(
        viewport={"width": 1280, "height": 800},
        user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    )
    page = context.new_page()
    stealth_sync(page)
    
    page.goto("https://www.gigsalad.com/gigs/tx/austin", wait_until="commit", timeout=30000)
    
    for i in range(8):
        time.sleep(5)
        title = page.title()
        print(f"[{i*5}s] Title: {title}")
        if "just a moment" not in title.lower():
            break
    
    content = page.content()
    print(f"\nFINAL: {page.title()} | Length: {len(content)}")
    
    items = page.query_selector_all("article, .card, .listing, .gig, [class*='gig'], [class*='event'], [class*='listing']")
    print(f"Items: {len(items)}")
    
    if len(items) > 0:
        for item in items[:3]:
            text = item.inner_text()[:100]
            print(f"  - {text}")
    
    browser.close()
