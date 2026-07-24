import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend", ".env"))

from playwright.sync_api import sync_playwright
import time

proxy = {"server": "http://gate.decodo.com:10001"}

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True, proxy=proxy)
    context = browser.new_context(
        viewport={"width": 1280, "height": 800},
        user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    )
    page = context.new_page()
    page.add_init_script("""
        Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
        window.chrome = { runtime: {} };
    """)
    page.goto("https://www.gigsalad.com/gigs/tx/austin", wait_until="commit", timeout=30000)
    time.sleep(8)
    
    title = page.title()
    url = page.url
    content = page.content()
    
    print(f"TITLE: {title}")
    print(f"URL: {url}")
    print(f"CONTENT LENGTH: {len(content)}")
    print(f"CONTENT PREVIEW: {content[:2000]}")
    
    browser.close()
