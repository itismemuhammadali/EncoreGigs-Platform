import requests
from bs4 import BeautifulSoup
from typing import List
from scraper.sources.base_scraper import BaseScraper
from scraper.models.gig import GigDetails, OrganizerDetails
import re

class FacebookScraper(BaseScraper):
    def __init__(self, target_groups: List[str] = None):
        super().__init__()
        self.target_groups = target_groups or ["Austin Musician Gigs"]

    @property
    def source_name(self) -> str:
        return "facebook"

    def _extract_contact_info(self, text: str) -> dict:
        """Regex to find emails and phones in public posts."""
        email_pattern = r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
        phone_pattern = r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}'
        
        emails = re.findall(email_pattern, text)
        phones = re.findall(phone_pattern, text)
        
        return {
            "email": emails[0] if emails else None,
            "phone": phones[0] if phones else None
        }

    def scrape(self) -> List[GigDetails]:
        print(f"Scraping Facebook Groups: {self.target_groups}...", flush=True)
        gigs = []
        
        # NOTE: Real Facebook scraping of groups usually requires authentication 
        # or a tool like Playwright. This implementation focuses on the DATA MAPPING
        # and extraction logic from the text content we'd get from those groups.
        
        for group in self.target_groups:
            # Improved sample post to be music-specific for demonstration
            sample_post_text = "Urgent: Need a Lead Guitarist for a Rock Gig at Antone's this Friday! Must have own gear. Pay is $300. Contact me at music.pro@example.com or 512-555-9876."
            
            # Apply musical filter
            if not self.is_music_related(sample_post_text):
                continue
                
            contact = self._extract_contact_info(sample_post_text)
            
            organizer = OrganizerDetails(
                name="Facebook Music Organizer",
                personal_email=contact["email"],
                personal_phone=contact["phone"],
                organization_type="Private"
            )

            gig = GigDetails(
                title=f"Musician Wanted: Rock Gig in {group}",
                description=sample_post_text,
                budget="$300",
                duration="Nightly",
                location="Austin, TX",
                source_url=f"https://facebook.com/groups/{group}",
                source_type=self.source_name,
                external_id="fb_music_sample_001",
                organizer=organizer
            )
            gigs.append(gig)
            
        return gigs
