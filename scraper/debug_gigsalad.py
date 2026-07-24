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
        window.chrome = { runtime: {}, app: { isInstalled: false } };
        Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
        Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3, 4, 5] });
        Object.defineProperty(navigator, 'platform', { get: () => 'MacIntel' });
        window.navigator.permissions.query = (params) => (
            Promise.resolve({ state: params.name === 'notifications' ? 'denied' : 'granted' })
        );
    """)
    
    page.goto("https://www.gigsalad.com/gigs/tx/austin", wait_until="commit", timeout=30000)
    
    for i in range(6):
        time.sleep(5)
        title = page.title()
        url = page.url
        print(f"[{i*5}s] Title: {title} | URL: {url}")
        if "just a moment" not in title.lower():
            break
    
    content = page.content()
    print(f"\nFINAL TITLE: {page.title()}")
    print(f"FINAL URL: {page.url}")
    print(f"CONTENT LENGTH: {len(content)}")
    
    items = page.query_selector_all("article, .card, .listing, .gig, [class*='gig'], [class*='event'], [class*='listing'], [class*='search']")
    print(f"Items found: {len(items)}")
    
    if len(content) > 5000:
        print(f"CONTENT TAIL: {content[-500:]}")
    
    browser.close()
