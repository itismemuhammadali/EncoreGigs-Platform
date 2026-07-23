import sys
import os
import time
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor
from dotenv import load_dotenv

# --- CRITICAL PATH FIX ---
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(CURRENT_DIR)
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

# Load env vars from backend/.env (where STRIPE, SMARTPROXY keys live)
load_dotenv(os.path.join(ROOT_DIR, "backend", ".env"))

try:
    from scraper.sources.craigslist_scraper import CraigslistScraper
    from scraper.sources.eventbrite_scraper import EventbriteScraper
    from scraper.sources.facebook_scraper import FacebookScraper
    from scraper.sources.gigsalad_scraper import GigSaladScraper
    from scraper.utils.database import DatabaseManager
except ImportError as e:
    print(f"IMPORT ERROR: {e}", flush=True)
    sys.exit(1)

class ScraperManager:
    def __init__(self):
        try:
            self.db_manager = DatabaseManager()
            self.scrapers = [
                CraigslistScraper(city="austin"),
                EventbriteScraper(location="austin"),
                FacebookScraper(target_groups=["Austin Musician Gigs"]),
                GigSaladScraper(location="austin"),
            ]
            print(f"ScraperManager initialized with {len(self.scrapers)} scrapers.", flush=True)
        except Exception as e:
            print(f"Error initializing ScraperManager: {e}", flush=True)
            raise

    def run_scraper_task(self, scraper, run_id):
        """Runs a single scraper and updates the database."""
        start_time = time.time()
        found_count = 0
        duplicates_count = 0
        errors_count = 0
        status = "success"
        
        try:
            print(f"Starting {scraper.source_name} parallel task...", flush=True)
            gigs = scraper.scrape()
            found_count = len(gigs)
            print(f"  {scraper.source_name} found {found_count} total items", flush=True)
            
            for gig in gigs:
                try:
                    result = self.db_manager.save_gig(gig)
                    if result == 2:
                        duplicates_count += 1
                    elif result == 0:
                        errors_count += 1
                except Exception as e:
                    print(f"  Error saving gig from {scraper.source_name}: {e}", flush=True)
                    errors_count += 1
                
        except Exception as e:
            print(f"  Error running {scraper.source_name}: {e}", flush=True)
            errors_count += 1
            status = "failed"
        
        duration = time.time() - start_time
        
        try:
            self.db_manager.log_run(
                source=scraper.source_name,
                imported=found_count,
                duplicates=duplicates_count,
                errors=errors_count,
                duration=duration,
                status=status,
                run_id=run_id
            )
            print(f"Finished {scraper.source_name} (Status: {status}, Found: {found_count}, Duration: {duration:.2f}s)", flush=True)
        except Exception as e:
            print(f"Error updating log for {scraper.source_name}: {e}", flush=True)

    def run_all(self):
        print(f"--- Starting Parallel Scraper Run at {datetime.now()} ---", flush=True)
        
        # 1. PRE-LOG: Create 'running' entries
        run_ids = {}
        for scraper in self.scrapers:
            try:
                run_id = self.db_manager.log_run(
                    source=scraper.source_name,
                    imported=0,
                    duplicates=0,
                    errors=0,
                    duration=0,
                    status="running"
                )
                run_ids[scraper.source_name] = run_id
            except Exception as e:
                print(f"Error pre-logging {scraper.source_name}: {e}", flush=True)

        # 2. ACTUAL SCRAPE (Parallel)
        with ThreadPoolExecutor(max_workers=len(self.scrapers)) as executor:
            for scraper in self.scrapers:
                executor.submit(self.run_scraper_task, scraper, run_ids.get(scraper.source_name))
            
        print("--- Parallel Scraper Run Finished ---", flush=True)

if __name__ == "__main__":
    try:
        manager = ScraperManager()
        manager.run_all()
    except Exception as e:
        print(f"CRITICAL SYSTEM ERROR: {e}", flush=True)
        import traceback
        traceback.print_exc()
