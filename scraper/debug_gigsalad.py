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
Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3, 4, 5] });
Object.defineProperty(navigator, 'platform', { get: () => 'MacIntel' });
window.chrome = { runtime: {}, app: { isInstalled: false, InstallState: { DISABLED: 'disabled', INSTALLED: 'installed', NOT_INSTALLED: 'not_installed' }, RunningState: { CANNOT_RUN: 'cannot_run', READY_TO_RUN: 'ready_to_run', RUNNING: 'running' } } };
const originalQuery = window.navigator.permissions.query;
window.navigator.permissions.query = (parameters) => (
    parameters.name === 'notifications'
        ? Promise.resolve({ state: Notification.permission })
        : originalQuery(parameters)
);
"""

with sync_playwright() as p:
    browser = p.chromium.launch(
        headless=False,
        proxy=proxy,
        args=[
            "--disable-blink-features=AutomationControlled",
            "--no-sandbox",
            "--disable-dev-shm-usage",
        ]
    )
    context = browser.new_context(
        viewport={"width": 1920, "height": 1080},
        user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
        locale="en-US",
        timezone_id="America/Chicago",
    )
    page = context.new_page()
    page.add_init_script(STEALTH_JS)

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
