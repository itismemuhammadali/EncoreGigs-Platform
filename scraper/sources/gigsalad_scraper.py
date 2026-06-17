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

    def scrape(self) -> List[GigDetails]:
        print(f"Scraping GigSalad in {self.location} using Playwright...", flush=True)
        gigs = []
        
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            context = browser.new_context(
                viewport={'width': 1280, 'height': 800},
                user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
            )
            page = context.new_page()
            
            # Manual stealth script to bypass basic detection
            page.add_init_script("""
                Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
                window.chrome = { runtime: {} };
                Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
                Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3, 4, 5] });
            """)
            
            try:
                # 'commit' is much faster as it doesn't wait for all tracking scripts/images
                page.goto(self.base_url, wait_until="commit", timeout=30000)

                # Give it a small fixed time for the HTML to actually appear
                time.sleep(5)

                # Try to find items using diverse selectors
                items = page.query_selector_all(".event-list-item, .gig-item, .listing-card, article, .card, .search-result, [class*='GigItem'], [class*='EventItem']")

                if not items:
                    # If nothing found, try scrolling once to trigger lazy loading
                    page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
                    time.sleep(3)
                    items = page.query_selector_all(".event-list-item, .gig-item, .listing-card, article, .card, .search-result, [class*='GigItem'], [class*='EventItem']")

                print(f"Found {len(items)} potential items on GigSalad page.")

                
                for element in items[:50]: # Check more items for variety
                    try:
                        title_elem = element.query_selector("h3, h2, .title, .gig-title")
                        if not title_elem: continue
                        title = title_elem.inner_text().strip()
                        
                        desc_elem = element.query_selector(".description, .summary, p")
                        description = desc_elem.inner_text().strip() if desc_elem else ""
                        
                        # Apply musical filter
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
                
        return gigs
