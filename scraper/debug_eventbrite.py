import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend", ".env"))

import requests

private_token = os.getenv("EVENTBRITE_PRIVATE_TOKEN", "")
headers = {"Authorization": f"Bearer {private_token}", "Content-Type": "application/json"}

# 1. Get categories
print("=== Categories ===")
r = requests.get("https://www.eventbriteapi.com/v3/categories/", headers=headers, timeout=10)
cats = r.json().get("categories", []) if r.status_code == 200 else []
music_cat = None
for c in cats:
    name = c.get("name", "").lower()
    if "music" in name or "concert" in name:
        print(f"  {c.get('id')}: {c.get('name')}")
        if "music" in name:
            music_cat = c.get("id")

# 2. Try subcategories
if music_cat:
    print(f"\n=== Subcategories for music ({music_cat}) ===")
    r2 = requests.get(f"https://www.eventbriteapi.com/v3/categories/{music_cat}/subcategories/", headers=headers, timeout=10)
    print(f"Status: {r2.status_code}")
    if r2.status_code == 200:
        for sc in r2.json().get("subcategories", [])[:10]:
            print(f"  {sc.get('id')}: {sc.get('name')}")

# 3. Try /v3/events/ with category_id filter
print("\n=== Events by category ===")
r3 = requests.get("https://www.eventbriteapi.com/v3/events/", headers=headers, params={"categories": music_cat, "expand": "venue,organizer", "status": "live"} if music_cat else {}, timeout=10)
print(f"Status: {r3.status_code}")
if r3.status_code == 200:
    events = r3.json().get("events", [])
    print(f"Events: {len(events)}")
    for e in events[:5]:
        print(f"  - {e.get('name',{}).get('text','?')}")
else:
    print(f"  {r3.text[:200]}")

# 4. Try /v3/events/ with venue_id (Austin Convention Center)
print("\n=== Events by venue ===")
r4 = requests.get("https://www.eventbriteapi.com/v3/venues/", headers=headers, params={"location.address": "austin,tx"}, timeout=10)
print(f"Venues status: {r4.status_code}")
if r4.status_code == 200:
    venues = r4.json().get("venues", [])
    print(f"Venues found: {len(venues)}")
    for v in venues[:5]:
        vid = v.get("id")
        name = v.get("name", "?")
        print(f"  {name} ({vid})")
        r5 = requests.get(f"https://www.eventbriteapi.com/v3/events/", headers=headers, params={"venue_id": vid, "expand": "organizer", "status": "live"}, timeout=10)
        if r5.status_code == 200:
            evts = r5.json().get("events", [])
            print(f"    Events at venue: {len(evts)}")
            for e in evts[:3]:
                print(f"    - {e.get('name',{}).get('text','?')}")
