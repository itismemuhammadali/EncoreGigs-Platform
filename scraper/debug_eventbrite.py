import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend", ".env"))

import requests

private_token = os.getenv("EVENTBRITE_PRIVATE_TOKEN", "")
headers = {"Authorization": f"Bearer {private_token}"}

# 1. Find our organization
print("=== Finding organization ===")
r = requests.get("https://www.eventbriteapi.com/v3/organizers/me/", headers=headers, timeout=10)
print(f"Status: {r.status_code}")
if r.status_code == 200:
    org = r.json()
    print(f"Name: {org.get('name')}")
    print(f"ID: {org.get('id')}")
    org_id = org.get("id")

    # 2. Get events for this org
    print(f"\n=== Events for org {org_id} ===")
    r2 = requests.get(f"https://www.eventbriteapi.com/v3/organizations/{org_id}/events/?expand=organizer,venue", headers=headers, timeout=10)
    print(f"Status: {r2.status_code}")
    if r2.status_code == 200:
        events = r2.json().get("events", [])
        print(f"Events: {len(events)}")
        for e in events[:5]:
            print(f"  - {e.get('name',{}).get('text','?')}")
else:
    print(f"  {r.text[:200]}")

# 3. Try POST to events/search
print("\n=== POST events/search ===")
r3 = requests.post("https://www.eventbriteapi.com/v3/events/search/", 
    headers=headers, 
    json={"q": "music", "location.address": "austin,tx"},
    timeout=10)
print(f"Status: {r3.status_code}")
if r3.status_code == 200:
    events = r3.json().get("events", [])
    print(f"Events: {len(events)}")
else:
    print(f"  {r3.text[:200]}")

# 4. Try event series
print("\n=== Event series ===")
r4 = requests.get("https://www.eventbriteapi.com/v3/series/", headers=headers, timeout=10)
print(f"Status: {r4.status_code}")

# 5. Try venues
print("\n=== Venues in Austin ===")
r5 = requests.get("https://www.eventbriteapi.com/v3/venues/?location.address=austin,tx", headers=headers, timeout=10)
print(f"Status: {r5.status_code}")
if r5.status_code == 200:
    venues = r5.json().get("venues", [])
    print(f"Venues: {len(venues)}")
    for v in venues[:5]:
        print(f"  - {v.get('name', '?')}")
