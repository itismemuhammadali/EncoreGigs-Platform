import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend", ".env"))

import requests
from bs4 import BeautifulSoup
import json

url = "https://www.eventbrite.com/d/tx--austin/music--events/"
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
}

print(f"Fetching: {url}")
try:
    response = requests.get(url, headers=headers, timeout=15)
    print(f"Status: {response.status_code}")
    print(f"Content length: {len(response.text)}")

    if "cloudflare" in response.text.lower() or "challenge" in response.text.lower():
        print("BLOCKED by Cloudflare")

    soup = BeautifulSoup(response.text, "html.parser")
    scripts = soup.find_all("script", type="application/ld+json")
    print(f"JSON-LD scripts found: {len(scripts)}")

    for script in scripts:
        try:
            data = json.loads(script.string)
            print(f"\nJSON-LD type: {data.get('@type', 'unknown')}")
            if isinstance(data, dict) and data.get("@type") == "ItemList":
                items = [li.get("item") for li in data.get("itemListElement", []) if li.get("item")]
                print(f"Events in ItemList: {len(items)}")
                for item in items[:3]:
                    print(f"  - {item.get('name', 'unknown')}")
            elif isinstance(data, list):
                print(f"Events in list: {len(data)}")
            else:
                print(f"Single item: {data.get('name', 'unknown')}")
        except Exception as e:
            print(f"JSON parse error: {e}")

except Exception as e:
    print(f"Request error: {e}")
