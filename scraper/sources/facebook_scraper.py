import json
import os
import re
from typing import List
from scraper.sources.base_scraper import BaseScraper
from scraper.models.gig import GigDetails, OrganizerDetails
from playwright.sync_api import sync_playwright
import time

COOKIES_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "facebook_cookies.json")

class FacebookScraper(BaseScraper):
    def __init__(self, target_groups: List[str] = None):
        super().__init__()
        self.target_groups = target_groups or [
            "AustinMusicians",
            "AustinBandmates",
            "ATXLiveMusic",
        ]

    @property
    def source_name(self) -> str:
        return "facebook"

    def _load_cookies(self) -> list:
        if not os.path.exists(COOKIES_FILE):
            print(f"WARNING: {COOKIES_FILE} not found.", flush=True)
            return []
        with open(COOKIES_FILE) as f:
            raw = json.load(f)
        for c in raw:
            ss = c.get("sameSite", "Lax")
            if ss not in ("Strict", "Lax", "None"):
                c["sameSite"] = "None" if ss == "no_restriction" else "Lax"
        return raw

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
            context.add_cookies(cookies)
            page = context.new_page()
            page.add_init_script(STEALTH_JS)

            for group in self.target_groups:
                url = f"https://www.facebook.com/groups/{group}/"
                print(f"  Loading group: {group}...", flush=True)
                try:
                    page.goto(url, wait_until="domcontentloaded", timeout=30000)
                    time.sleep(8)

                    if "login" in page.url.lower():
                        print(f"  WARNING: Session expired for {group}.", flush=True)
                        continue

                    for sel in [
                        "button:has-text('Decline optional cookies')",
                        "button:has-text('Allow all cookies')",
                        "[data-cookiebanner='accept_button']",
                    ]:
                        try:
                            btn = page.query_selector(sel)
                            if btn and btn.is_visible():
                                btn.click()
                                time.sleep(2)
                                break
                        except:
                            continue

                    try:
                        page.keyboard.press("Escape")
                        time.sleep(1)
                    except:
                        pass

                    for _ in range(6):
                        page.evaluate("window.scrollBy(0, 1000)")
                        time.sleep(2)

                    articles = page.query_selector_all("[role='article']")
                    print(f"  Found {len(articles)} posts in {group}", flush=True)

                    for article in articles:
                        try:
                            text = article.inner_text().strip()
                            if len(text) < 30:
                                continue
                            if not self.is_music_related(text):
                                continue

                            if text.startswith("FILLED!"):
                                continue

                            contact = self._extract_contact_info(text)
                            lines = text.split("\n")
                            title = lines[0][:100] if lines else "Facebook Gig Post"

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
                                source_url=url,
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
