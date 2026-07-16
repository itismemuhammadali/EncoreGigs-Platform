import requests
from bs4 import BeautifulSoup
from typing import List
from scraper.sources.base_scraper import BaseScraper
from scraper.models.gig import GigDetails, OrganizerDetails
from datetime import datetime
import re
from concurrent.futures import ThreadPoolExecutor

class CraigslistScraper(BaseScraper):
    def __init__(self, city: str = "austin"):
        super().__init__()
        self.city = city
        # Target 'muc' (musicians) community section with a search query for better variety
        self.base_url = f"https://{city}.craigslist.org/search/muc?query=music"

    @property
    def source_name(self) -> str:
        return "craigslist"

    def _get_detail_page(self, url: str) -> dict:
        """Visits the individual gig page to get deeper details."""
        try:
            res = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=5)
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
            # print(f"Error fetching details from {url}: {e}")
            return {}

    def process_result(self, res):
        """Processes a single search result into a GigDetails object."""
        try:
            link_elem = res if res.name == 'a' else res.select_one('a')
            if not link_elem: return None
            link = link_elem['href']
            if not link.startswith('http'):
                link = f"https://{self.city}.craigslist.org{link}"
            
            title_elem = res.select_one('.title, .result-title, .titlestring')
            title = title_elem.text.strip() if title_elem else link.split('/')[-1].replace('.html', '').replace('-', ' ')
            
            # Preliminary check on title
            if not self.is_music_related(title):
                return None
            
            # Visit detail page
            details = self._get_detail_page(link)
            description = details.get("description", "No description available.")
            
            # Check description too for music relevance
            if not self.is_music_related(description):
                return None
            
            organizer = OrganizerDetails(
                name="Craigslist Poster",
                organization_type="Other",
                description="Organization details available on Craigslist post."
            )

            external_id = res.get('data-pid')
            if not external_id and link:
                match = re.search(r'/(\d+)\.html', link)
                if match:
                    external_id = match.group(1)
            
            return GigDetails(
                title=title,
                description=description,
                budget=details.get("compensation", "Not specified"),
                location=f"{self.city.capitalize()}, TX",
                image_url=details.get("images")[0] if details.get("images") else None,
                source_url=link,
                source_type=self.source_name,
                external_id=external_id or f"cl_{hash(link)}",
                organizer=organizer
            )
        except Exception:
            return None

    def scrape(self) -> List[GigDetails]:
        print(f"Scraping Craigslist ({self.city})...")
        gigs = []
        
        try:
            response = requests.get(self.base_url, headers={"User-Agent": "Mozilla/5.0"}, timeout=10)
            if response.status_code != 200:
                return []

            soup = BeautifulSoup(response.text, 'html.parser')
            # Try multiple selectors as Craigslist updates frequently
            results = soup.select('li.cl-static-search-result, li.result-row, .gallery-card')
            
            if not results:
                # Fallback to broad search for links
                results = soup.select('a[href*="/muc/"]')

            # Limit to top 40 for speed in real-time demo
            target_results = results[:40]
            print(f"Found {len(results)} potential results on Craigslist. Processing top {len(target_results)} in parallel...", flush=True)
            
            with ThreadPoolExecutor(max_workers=10) as executor:
                futures = [executor.submit(self.process_result, res) for res in target_results]
                for future in futures:
                    gig = future.result()
                    if gig:
                        gigs.append(gig)
                
        except Exception as e:
            print(f"Error: {e}")
            
        return gigs
