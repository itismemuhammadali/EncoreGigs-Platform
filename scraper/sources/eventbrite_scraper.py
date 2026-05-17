import requests
import json
from bs4 import BeautifulSoup
from typing import List
from scraper.sources.base_scraper import BaseScraper
from scraper.models.gig import GigDetails, OrganizerDetails

class EventbriteScraper(BaseScraper):
    def __init__(self, location: str = "austin"):
        self.location = location
        # Search for music events in the specified location
        self.base_url = f"https://www.eventbrite.com/d/tx--{location}/music--events/"

    @property
    def source_name(self) -> str:
        return "eventbrite"

    def scrape(self) -> List[GigDetails]:
        print(f"Scraping Eventbrite in {self.location}...")
        gigs = []
        
        try:
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
            }
            response = requests.get(self.base_url, headers=headers, timeout=15)
            if response.status_code != 200:
                return []

            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Eventbrite uses JSON-LD for event data
            scripts = soup.find_all('script', type='application/ld+json')
            
            for script in scripts:
                try:
                    data = json.loads(script.string)
                    # JSON-LD can be a single object or a list
                    items = data if isinstance(data, list) else [data]
                    
                    for item in items:
                        if item.get("@type") == "Event":
                            organizer_data = item.get("organizer", {})
                            organizer = OrganizerDetails(
                                name=organizer_data.get("name", "Eventbrite Organizer"),
                                organization_name=organizer_data.get("name"),
                                organization_type="Event Planner",
                                website=organizer_data.get("url")
                            )

                            location_data = item.get("location", {})
                            venue_name = location_data.get("name", "Venue")
                            address = location_data.get("address", {})
                            full_location = f"{venue_name}, {address.get('addressLocality', self.location)}"

                            gig = GigDetails(
                                title=item.get("name", "Unknown Event"),
                                description=item.get("description", "No description provided."),
                                venue=venue_name,
                                location=full_location,
                                date=item.get("startDate", "")[:10] if item.get("startDate") else None,
                                time=item.get("startDate", "")[11:16] if item.get("startDate") else None,
                                image_url=item.get("image"),
                                source_url=item.get("url", self.base_url),
                                source_type=self.source_name,
                                external_id=item.get("url", "").split("-")[-1] or "eb_id",
                                organizer=organizer
                            )
                            gigs.append(gig)
                except:
                    continue
                    
        except Exception as e:
            print(f"Error scraping Eventbrite: {e}")
            
        return gigs
