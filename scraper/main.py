import sys
import os
# Add the root project directory to the path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from typing import List
from scraper.sources.craigslist_scraper import CraigslistScraper
from scraper.sources.eventbrite_scraper import EventbriteScraper
from scraper.sources.facebook_scraper import FacebookScraper
from scraper.utils.database import DatabaseManager
from scraper.models.gig import GigDetails

class ScraperManager:
    def __init__(self):
        self.db_manager = DatabaseManager()
        self.scrapers = [
            CraigslistScraper(city="austin"),
            EventbriteScraper(location="austin"),
            FacebookScraper(target_groups=["Austin Musician Gigs"]),
        ]

    def run_all(self):
        print("--- Starting Scraper Run ---")
        for scraper in self.scrapers:
            try:
                gigs = scraper.scrape()
                print(f"Collected {len(gigs)} from {scraper.source_name}")
                
                for gig in gigs:
                    self.db_manager.save_gig(gig)
                    
            except Exception as e:
                print(f"Error running {scraper.source_name}: {e}")
        print("--- Scraper Run Finished ---")

if __name__ == "__main__":
    manager = ScraperManager()
    manager.run_all()
