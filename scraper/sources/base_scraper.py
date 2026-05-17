from abc import ABC, abstractmethod
from typing import List
from scraper.models.gig import GigDetails

class BaseScraper(ABC):
    @abstractmethod
    def scrape(self) -> List[GigDetails]:
        """
        Main method to perform scraping.
        Returns a list of GigDetails objects.
        """
        pass

    @property
    @abstractmethod
    def source_name(self) -> str:
        """
        Returns the name of the source (e.g., 'craigslist').
        """
        pass
