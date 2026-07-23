from typing import List
from scraper.sources.base_scraper import BaseScraper
from scraper.models.gig import GigDetails, OrganizerDetails
from playwright.sync_api import sync_playwright
import time
import re
import os

class GigSaladScraper(BaseScraper):
    def __init__(self, location: str = "austin"):
        super().__init__()
        self.location = location
        self.base_url = f"https://www.gigsalad.com/gigs/tx/{location}"

    @property
    def source_name(self) -> str:
        return "gigsalad"

    def _get_proxy(self):
        api_key = os.getenv("SMARTPROXY_API_KEY", "")
        if not api_key:
            print("WARNING: SMARTPROXY_API_KEY not set. GigSalad will likely get 403.", flush=True)
            return None
        return {
            "server": "http://gate.smartproxy.com:7777",
            "username": "OG",
            "password": api_key,
        }

    def _test_proxy(self, browser_type, proxy):
        """Quick connectivity test through the proxy before full scrape."""
        try:
            test_browser = browser_type.launch(headless=True, proxy=proxy)
            test_page = test_browser.new_page()
            test_page.goto("https://httpbin.org/ip", timeout=15000)
            ip = test_page.inner_text()
            test_browser.close()
            print(f"  Proxy working. Proxy IP: {ip.strip()[:50]}", flush=True)
            return True
        except Exception as e:
            print(f"  Proxy test failed: {e}", flush=True)
            try:
                test_browser.close()
            except Exception:
                pass
            return False

    def scrape(self) -> List[GigDetails]:
        print(f"Scraping GigSalad in {self.location} using Playwright...", flush=True)
        gigs = []

        proxy = self._get_proxy()

        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            use_proxy = False

            if proxy:
                print(f"  Testing SmartProxy connection...", flush=True)
                if self._test_proxy(p.chromium, proxy):
                    browser.close()
                    browser = p.chromium.launch(headless=True, proxy=proxy)
                    use_proxy = True
                else:
                    print("  Falling back to direct connection (may get 403)", flush=True)

            context = browser.new_context(
                viewport={'width': 1280, 'height': 800},
                user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
            )
            page = context.new_page()

            page.add_init_script("""
                Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
                window.chrome = { runtime: {} };
                Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
                Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3, 4, 5] });
            """)

            try:
                page.goto(self.base_url, wait_until="commit", timeout=30000)
                time.sleep(5)

                items = page.query_selector_all(".event-list-item, .gig-item, .listing-card, article, .card, .search-result, [class*='GigItem'], [class*='EventItem']")

                if not items:
                    page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
                    time.sleep(3)
                    items = page.query_selector_all(".event-list-item, .gig-item, .listing-card, article, .card, .search-result, [class*='GigItem'], [class*='EventItem']")

                print(f"Found {len(items)} potential items on GigSalad page.")

                for element in items[:50]:
                    try:
                        title_elem = element.query_selector("h3, h2, .title, .gig-title")
                        if not title_elem: continue
                        title = title_elem.inner_text().strip()

                        desc_elem = element.query_selector(".description, .summary, p")
                        description = desc_elem.inner_text().strip() if desc_elem else ""

                        if not self.is_music_related(title) and not self.is_music_related(description):
                            continue

                        link_elem = element.query_selector("a")
                        href = link_elem.get_attribute("href") if link_elem else ""
                        if not href: continue
                        link = "https://www.gigsalad.com" + href if href.startswith('/') else href

                        loc_elem = element.query_selector(".location, .city")
                        location = loc_elem.inner_text().strip() if loc_elem else self.location

                        external_id = "gs_" + (re.search(r'-(\d+)$', link).group(1) if re.search(r'-(\d+)$', link) else str(time.time()))

                        organizer = OrganizerDetails(
                            name="GigSalad Client",
                            organization_type="Private"
                        )

                        gig = GigDetails(
                            title=title,
                            description=description,
                            location=location,
                            source_url=link,
                            source_type=self.source_name,
                            external_id=external_id,
                            organizer=organizer
                        )
                        gigs.append(gig)
                    except Exception:
                        continue

            except Exception as e:
                print(f"Error during GigSalad session: {e}")
            finally:
                browser.close()

        print(f"GigSalad: found {len(gigs)} music gigs (proxy: {'yes' if use_proxy else 'no'})", flush=True)
        return gigs
