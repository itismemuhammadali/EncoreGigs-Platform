import requests
from typing import List
from scraper.sources.base_scraper import BaseScraper
from scraper.models.gig import GigDetails, OrganizerDetails
import os

class EventbriteScraper(BaseScraper):
    def __init__(self, location: str = "austin"):
        super().__init__()
        self.location = location
        self.api_key = os.getenv("EVENTBRITE_API_KEY", "")

    @property
    def source_name(self) -> str:
        return "eventbrite"

    def scrape(self) -> List[GigDetails]:
        print(f"Scraping Eventbrite in {self.location}...", flush=True)
        gigs = []

        if self.api_key:
            gigs = self._scrape_api()
            if gigs:
                return gigs
            print("  API scraping failed, falling back to HTML...", flush=True)

        return self._scrape_html()

    def _scrape_api(self) -> List[GigDetails]:
        gigs = []
        try:
            url = "https://www.eventbriteapi.com/v3/events/search/"
            params = {
                "q": "music live band musician",
                "location.address": f"{self.location}, TX",
                "location.within": "25mi",
                "expand": "organizer,venue",
                "sort_by": "date",
            }
            headers = {"Authorization": f"Bearer {self.api_key}"}

            response = requests.get(url, params=params, headers=headers, timeout=15)
            if response.status_code != 200:
                print(f"  Eventbrite API error: {response.status_code}", flush=True)
                return gigs

            data = response.json()
            events = data.get("events", [])
            print(f"  Eventbrite API returned {len(events)} events", flush=True)

            for event in events:
                try:
                    title = event.get("name", {}).get("text", "Unknown Event")
                    description = event.get("description", {}).get("text", "")

                    if not self.is_music_related(title) and not self.is_music_related(description):
                        continue

                    organizer_data = event.get("organizer", {})
                    venue_data = event.get("venue", {})
                    address = venue_data.get("address", {})

                    organizer = OrganizerDetails(
                        name=organizer_data.get("name", "Eventbrite Organizer"),
                        organization_name=organizer_data.get("name"),
                        organization_type="Event Planner",
                    )

                    locality = address.get("localized_address_display", self.location)

                    gig = GigDetails(
                        title=title,
                        description=description[:500] if description else "",
                        location=locality,
                        date=event.get("start", {}).get("local", "")[:10] if event.get("start") else None,
                        time=event.get("start", {}).get("local", "")[11:16] if event.get("start") else None,
                        image_url=event.get("logo", {}).get("url") if event.get("logo") else None,
                        source_url=event.get("url", ""),
                        source_type=self.source_name,
                        external_id=f"eb_{event.get('id', '')}",
                        organizer=organizer,
                    )
                    gigs.append(gig)
                except Exception:
                    continue

        except Exception as e:
            print(f"  Eventbrite API error: {e}", flush=True)

        return gigs

    def _scrape_html(self) -> List[GigDetails]:
        import json
        from bs4 import BeautifulSoup

        gigs = []
        try:
            url = f"https://www.eventbrite.com/d/tx--{self.location}/music--events/"
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
            }
            proxies = {"http": "http://ONLYGIGZ:v6Uyj0_zhW77iNlIvx@gate.decodo.com:10001", "https": "http://ONLYGIGZ:v6Uyj0_zhW77iNlIvx@gate.decodo.com:10001"}
            response = requests.get(url, headers=headers, proxies=proxies, timeout=15)
            if response.status_code != 200:
                return gigs

            soup = BeautifulSoup(response.text, "html.parser")
            scripts = soup.find_all("script", type="application/ld+json")

            for script in scripts:
                try:
                    data = json.loads(script.string)
                    if isinstance(data, dict) and data.get("@type") == "ItemList":
                        items = [li.get("item") for li in data.get("itemListElement", []) if li.get("item")]
                    else:
                        items = data if isinstance(data, list) else [data]

                    for item in items:
                        if not item or item.get("@type") != "Event":
                            continue

                        title = item.get("name", "Unknown Event")
                        description = item.get("description", "")

                        if not self.is_music_related(title) and not self.is_music_related(description):
                            continue

                        organizer_data = item.get("organizer", {})
                        organizer = OrganizerDetails(
                            name=organizer_data.get("name", "Eventbrite Organizer"),
                            organization_name=organizer_data.get("name"),
                            organization_type="Event Planner",
                            website=organizer_data.get("url"),
                        )

                        location_data = item.get("location", {})
                        venue_name = location_data.get("name", "Venue")
                        address_data = location_data.get("address", {})
                        locality = address_data.get("addressLocality", self.location) if isinstance(address_data, dict) else self.location
                        full_location = f"{venue_name}, {locality}"

                        gig = GigDetails(
                            title=title,
                            description=description[:500] if description else "",
                            location=full_location,
                            date=item.get("startDate", "")[:10] if item.get("startDate") else None,
                            time=item.get("startDate", "")[11:16] if item.get("startDate") else None,
                            image_url=item.get("image"),
                            source_url=item.get("url", url),
                            source_type=self.source_name,
                            external_id=f"eb_{item.get('url', '').split('-')[-1] or 'id'}",
                            organizer=organizer,
                        )
                        gigs.append(gig)
                except Exception:
                    continue

        except Exception as e:
            print(f"  Eventbrite HTML error: {e}", flush=True)

        return gigs
