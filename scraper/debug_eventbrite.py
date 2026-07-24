import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend", ".env"))

import requests

private_token = os.getenv("EVENTBRITE_PRIVATE_TOKEN", "")
api_key = os.getenv("EVENTBRITE_API_KEY", "")
client_secret = os.getenv("EVENTBRITE_CLIENT_SECRET", "")

print(f"private_token: {private_token}")
print(f"api_key: {api_key}")
print(f"client_secret: {client_secret[:10]}...")

# Try every possible Eventbrite endpoint
endpoints = [
    ("GET /v3/events/", f"https://www.eventbriteapi.com/v3/events/"),
    ("GET /v3/events/search", "https://www.eventbriteapi.com/v3/events/search"),
    ("GET /v3/events/search/", "https://www.eventbriteapi.com/v3/events/search/"),
    ("POST /v3/events/search/", "https://www.eventbriteapi.com/v3/events/search/"),
    ("GET /v3/destination/search", "https://www.eventbriteapi.com/v3/destination/search"),
    ("GET /v3/venue/search", "https://www.eventbriteapi.com/v3/venue/search"),
    ("GET /v3/categories/", "https://www.eventbriteapi.com/v3/categories/"),
    ("GET /v3/organizers/", "https://www.eventbriteapi.com/v3/organizers/"),
    ("GET /v3/saved_events/", "https://www.eventbriteapi.com/v3/saved_events/"),
]

for label, url in endpoints:
    for auth_name, token in [("private", private_token), ("api_key", api_key)]:
        headers = {"Authorization": f"Bearer {token}"}
        params = {"q": "music", "location.address": "austin,tx"} if "search" in url else {}
        method = "POST" if "POST" in label else "GET"
        try:
            if method == "POST":
                r = requests.post(url, headers=headers, json=params, timeout=10)
            else:
                r = requests.get(url, headers=headers, params=params, timeout=10)
            if r.status_code != 404:
                print(f"{r.status_code} | {auth_name:10s} | {label}")
                if r.status_code == 200:
                    print(f"  -> {r.text[:200]}")
        except Exception as e:
            print(f"ERR | {auth_name:10s} | {label} | {str(e)[:60]}")
