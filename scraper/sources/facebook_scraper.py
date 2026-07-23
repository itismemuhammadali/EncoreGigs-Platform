import json
import os
import re
from typing import List
from scraper.sources.base_scraper import BaseScraper
from scraper.models.gig import GigDetails, OrganizerDetails
from playwright.sync_api import sync_playwright

COOKIES_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "facebook_cookies.json")

class FacebookScraper(BaseScraper):
    def __init__(self, target_groups: List[str] = None):
        super().__init__()
        self.target_groups = target_groups or [
            "AustinMusicianGigs",
            "AustinMusicians",
            "ATXLiveMusic",
            "AustinBandmates",
        ]

    @property
    def source_name(self) -> str:
        return "facebook"

    def _load_cookies(self) -> list:
        if not os.path.exists(COOKIES_FILE):
            print(f"WARNING: {COOKIES_FILE} not found. Facebook scraper will not work.", flush=True)
            return []
        with open(COOKIES_FILE) as f:
            return json.load(f)

    def _extract_contact_info(self, text: str) -> dict:
        emails = re.findall(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', text)
        phones = re.findall(r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}', text)
        return {"email": emails[0] if emails else None, "phone": phones[0] if phones else None}

    def scrape(self) -> List[GigDetails]:
        print(f"Scraping Facebook Groups: {self.target_groups}...", flush=True)
        gigs = []

        cookies = self._load_cookies()
        if not cookies:
            return gigs

        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            context = browser.new_context(
                viewport={"width": 1280, "height": 800},
                user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            )

            context.add_cookies(cookies)
            page = context.new_page()

            for group in self.target_groups:
                url = f"https://www.facebook.com/groups/{group}/"
                print(f"  Loading group: {group}...", flush=True)
                try:
                    page.goto(url, wait_until="domcontentloaded", timeout=30000)
                    page.wait_for_timeout(5000)

                    if "login" in page.url.lower():
                        print(f"  WARNING: Session expired for {group}. Need fresh cookies.", flush=True)
                        continue

                    posts = page.query_selector_all("[data-ad-rendering-role='story_message'], [data-ad-preview='message'], div[dir='auto']")
                    print(f"  Found {len(posts)} post elements in {group}", flush=True)

                    for post in posts[:30]:
                        try:
                            text = post.inner_text().strip()
                            if len(text) < 20:
                                continue
                            if not self.is_music_related(text):
                                continue

                            contact = self._extract_contact_info(text)
                            lines = text.split("\n")
                            title = lines[0][:100] if lines else "Facebook Gig Post"

                            post_link = page.evaluate(
                                """(el) => {
                                    let node = el;
                                    while (node && node.tagName !== 'A') node = node.parentElement;
                                    return node ? node.href : null;
                                }""",
                                post,
                            )

                            organizer = OrganizerDetails(
                                name="Facebook Group Member",
                                personal_email=contact["email"],
                                personal_phone=contact["phone"],
                                organization_type="Private",
                            )

                            gig = GigDetails(
                                title=title,
                                description=text[:500],
                                location="Austin, TX",
                                source_url=post_link or url,
                                source_type=self.source_name,
                                external_id=f"fb_{group}_{hash(text[:100])}",
                                organizer=organizer,
                            )
                            gigs.append(gig)
                        except Exception:
                            continue

                except Exception as e:
                    print(f"  Error scraping {group}: {e}", flush=True)

            browser.close()

        print(f"Facebook: found {len(gigs)} music gigs across {len(self.target_groups)} groups", flush=True)
        return gigs
