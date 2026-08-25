import re
from typing import Any, List, Union

ABBREVIATIONS = {
    "tx", "la", "ny", "ca", "fl", "ga", "nc", "sc", "va", "dc",
    "usa", "uk", "nj", "pa", "oh", "mi", "il", "tn", "al", "ms",
    "ar", "mo", "az", "co", "wa", "or", "nv"
}

def capitalize_words(text: Any) -> str:
    """
    Capitalizes the first letter of every word (Title Case).
    Preserves uppercase for state abbreviations like TX, LA, NY, USA.
    Handles punctuation, spaces, slashes, etc.
    """
    if not text or not isinstance(text, str):
        return "" if text is None else str(text)
    
    def replace_match(match):
        word = match.group(0)
        word_lower = word.lower()
        if word_lower in ABBREVIATIONS:
            return word.upper()
        return word[0].upper() + word[1:]

    return re.sub(r'\b[a-zA-Z]+\b', replace_match, text)

def capitalize_list(items: Any) -> List[str]:
    """Capitalizes a list of strings."""
    if not items or not isinstance(items, list):
        return []
    return [capitalize_words(item) for item in items if isinstance(item, str)]
