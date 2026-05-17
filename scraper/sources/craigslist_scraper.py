import requests
from bs4 import BeautifulSoup
from typing import List
from scraper.sources.base_scraper import BaseScraper
from scraper.models.gig import GigDetails, OrganizerDetails
from datetime import datetime
import re

class CraigslistScraper(BaseScraper):
    def __init__(self, city: str = "austin"):
        self.city = city
        self.base_url = f"https://{city}.craigslist.org/search/ggg"

    @property
    def source_name(self) -> str:
        return "craigslist"

    def _get_detail_page(self, url: str) -> dict:
        """Visits the individual gig page to get deeper details."""
        try:
            res = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=10)
            if res.status_code != 200:
                return {}
            
            soup = BeautifulSoup(res.text, 'html.parser')
            
            # Extract Description
            desc_elem = soup.select_one('#postingbody')
            description = ""
            if desc_elem:
                # Remove the 'QR Code' text Craigslist inserts
                for extra in desc_elem.select('.print-qrcode-container'):
                    extra.decompose()
                description = desc_elem.text.strip()

            # Extract Compensation/Pay
            compensation = "Not specified"
            attr_groups = soup.select('.attrgroup span')
            for span in attr_groups:
                if 'compensation' in span.text.lower():
                    compensation = span.text.replace('compensation:', '').strip()

            # Extract Images
            images = []
            img_elems = soup.select('.thumb img')
            if img_elems:
                images = [img['src'].replace('50x50c', '600x450') for img in img_elems]
            elif soup.select_one('.userbody img'):
                images = [soup.select_one('.userbody img')['src']]

            return {
                "description": description,
                "compensation": compensation,
                "images": images
            }
        except Exception as e:
            print(f"Error fetching details from {url}: {e}")
            return {}

    def scrape(self) -> List[GigDetails]:
        print(f"Scraping Craigslist ({self.city})...")
        gigs = []
        
        try:
            response = requests.get(self.base_url, headers={"User-Agent": "Mozilla/5.0"})
            if response.status_code != 200:
                return []

            soup = BeautifulSoup(response.text, 'html.parser')
            results = soup.select('.result-row')
            
            for res in results[:5]: # Limit to 5 for thoroughness in testing
                title_elem = res.select_one('.result-title')
                link = title_elem['href'] if title_elem else ""
                title = title_elem.text if title_elem else "Unknown Gig"
                
                # Visit detail page
                details = self._get_detail_page(link)
                
                organizer = OrganizerDetails(
                    name="Craigslist Poster",
                    organization_type="Other",
                    description="Organization details available on Craigslist post."
                )

                gig = GigDetails(
                    title=title,
                    description=details.get("description", "No description available."),
                    budget=details.get("compensation", "Not specified"),
                    location=f"{self.city.capitalize()}, TX",
                    image_url=details.get("images")[0] if details.get("images") else None,
                    source_url=link,
                    source_type=self.source_name,
                    external_id=res.get('data-pid', 'unknown'),
                    organizer=organizer
                )
                gigs.append(gig)
                
        except Exception as e:
            print(f"Error: {e}")
            
        return gigs
