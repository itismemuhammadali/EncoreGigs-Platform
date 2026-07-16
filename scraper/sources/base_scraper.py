from abc import ABC, abstractmethod
from typing import List
from scraper.models.gig import GigDetails

class BaseScraper(ABC):
    def __init__(self):
        self.music_keywords = [
            "band", "musician", "singer", "drummer", "guitarist", "bass", "keyboard", 
            "vocalist", "gig", "performance", "live music", "pianist", "producer",
            "violin", "cello", "saxophone", "trumpet", "dj ", "artist", "wedding band",
            "concert", "orchestra", "symphony", "recording studio", "mastering",
            "songwriter", "composer", "musical", "instrumentalist", "jazz", "rock",
            "blues", "classical", "hip hop", "r&b", "country music", "pop music",
            "acoustic", "session player", "horn", "brass", "flute", "percussion",
            "backup", "touring", "rehearsal", "mixing", "audio engineer", "busking",
            "festival", "showcase", "open mic", "karaoke", "ensemble", "trio", "quartet"
        ]

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

    def is_music_related(self, text: str) -> bool:
        """Common filter to check if text contains music-related keywords."""
        if not text:
            return False
        text_lower = text.lower()
        for keyword in self.music_keywords:
            if keyword.lower() in text_lower:
                return True
        music_patterns = ["live entertainment", "event", "party", "club", "bar", "venue", "hire", "needed", "wanted", "looking for", "seeking"]
        for pattern in music_patterns:
            if pattern in text_lower:
                return True
        return False
