import json
import os
import re
from typing import List, Optional
from scraper.sources.base_scraper import BaseScraper
from scraper.models.gig import GigDetails, OrganizerDetails
from playwright.sync_api import sync_playwright
import time

COOKIES_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "facebook_cookies.json")

class FacebookScraper(BaseScraper):
    def __init__(self, target_groups: Optional[List[str]] = None):
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

    def _normalize_group_url(self, group: str) -> str:
        group_str = group.strip()
        if group_str.startswith("http://") or group_str.startswith("https://"):
            slug = group_str.rstrip("/").split("/groups/")[-1]
            return f"https://www.facebook.com/groups/{slug}/"
        return f"https://www.facebook.com/groups/{group_str.rstrip('/')}/"

    def scrape(self) -> List[GigDetails]:
        print(f"Scraping Facebook Groups ({len(self.target_groups)} groups queued)...", flush=True)
        gigs = []

        cookies = self._load_cookies()
        if not cookies:
            return gigs

        STEALTH_JS = """
        Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
        window.chrome = { runtime: {}, app: { isInstalled: false } };
        """

        with sync_playwright() as p:
            browser = p.chromium.launch(
                headless=True,
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
                url = self._normalize_group_url(group)
                print(f"  Loading group: {url}...", flush=True)
                try:
                    if page.is_closed():
                        page = context.new_page()
                        page.add_init_script(STEALTH_JS)

                    page.goto(url, wait_until="domcontentloaded", timeout=30000)

                    time.sleep(4)

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

                    post_elements = page.query_selector_all("[role='article'], [data-ad-rendering-role='story_message'], div[data-ad-preview='message']")
                    print(f"  Found {len(post_elements)} posts/stories in {group}", flush=True)

                    seen_texts = set()
                    for elem in post_elements:
                        try:
                            text = elem.inner_text().strip()
                            if len(text) < 30 or text in seen_texts:
                                continue
                            seen_texts.add(text)
                            if not self.is_music_related(text):
                                continue

                            if text.startswith("FILLED!"):
                                continue

                            contact = self._extract_contact_info(text)
                            lines = [l.strip() for l in text.split("\n") if l.strip() and len(l.strip()) > 5]
                            title = "Facebook Gig Post"
                            for line in lines:
                                if not any(skip in line.lower() for skip in ["like", "comment", "share", "view more", "all reactions", "·"]):
                                    title = line[:100]
                                    break

                            # Extract exact post permalink & poster profile URL
                            post_permalink = url
                            poster_name = "Facebook Group Member"
                            poster_profile_url = None

                            try:
                                post_link_found = False
                                for a in elem.query_selector_all("a[href]"):
                                    h = a.get_attribute("href") or ""
                                    if any(k in h for k in ["/posts/", "/permalink/", "story_fbid", "fbid=", "multi_permalinks", "set=a."]):
                                        if h.startswith("/"):
                                            h = "https://www.facebook.com" + h
                                        post_permalink = h.split("&__cft__")[0].split("?__cft__")[0].split("&__tn__")[0].split("?__tn__")[0].split("&ref=")[0].split("?ref=")[0]
                                        post_link_found = True
                                        break
                                
                                if not post_link_found:
                                    link_elem = elem.query_selector("a[href*='/posts/'], a[href*='/permalink/'], a[href*='story_fbid'], a[href*='multi_permalinks'], a[href*='fbid='], a[href*='set=a.']")
                                    if link_elem:
                                        h = link_elem.get_attribute("href")
                                        if h:
                                            if h.startswith("/"):
                                                h = "https://www.facebook.com" + h
                                            post_permalink = h.split("&__cft__")[0].split("?__cft__")[0].split("&__tn__")[0].split("?__tn__")[0].split("&ref=")[0].split("?ref=")[0]

                                # Look for author profile link
                                author_elem = elem.query_selector("h2 a, h3 a, h4 a, a[role='link'][href*='facebook.com'], a[role='link'][href*='/user/'], a[role='link'][href*='profile.php']")
                                if author_elem:
                                    a_name = author_elem.inner_text().strip()
                                    a_href = author_elem.get_attribute("href")
                                    if a_name and len(a_name) > 1 and not any(k in a_name.lower() for k in ["like", "comment", "share", "group", "joined", "member"]):
                                        poster_name = a_name
                                    if a_href:
                                        if a_href.startswith("/"):
                                            a_href = "https://www.facebook.com" + a_href
                                        poster_profile_url = a_href.split("&__cft__")[0].split("?__cft__")[0]
                            except Exception:
                                pass

                            organizer = OrganizerDetails(
                                name=poster_name,
                                personal_email=contact["email"],
                                personal_phone=contact["phone"],
                                profile_url=poster_profile_url,
                                organization_type="Private",
                            )

                            gig = GigDetails(
                                title=title,
                                description=text[:500],
                                location="Austin, TX",
                                source_url=post_permalink,
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
