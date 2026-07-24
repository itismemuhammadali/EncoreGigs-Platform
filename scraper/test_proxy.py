"""Quick test to verify SmartProxy connectivity before running the full scraper."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend", ".env"))

api_key = os.getenv("SMARTPROXY_API_KEY", "")
if not api_key:
    print("ERROR: SMARTPROXY_API_KEY not set in backend/.env")
    sys.exit(1)

print(f"SmartProxy key loaded ({len(api_key)} chars)")

import requests

# Try multiple auth formats
tests = [
    ("No auth (IP whitelist only)", f"http://gate.decodo.com:10001"),
    ("User OG, no password", f"http://OG:@gate.decodo.com:10001"),
    ("User OG + API key", f"http://OG:{api_key}@gate.decodo.com:10001"),
    ("User OG + API key port 10002", f"http://OG:{api_key}@gate.decodo.com:10002"),
]

for label, proxy_url in tests:
    proxies = {"http": proxy_url, "https": proxy_url}
    print(f"\nTest: {label}")
    print(f"  URL: {proxy_url[:60]}...")
    try:
        r = requests.get("https://ip.decodo.com/json", proxies=proxies, timeout=15)
        print(f"  SUCCESS - Status: {r.status_code}")
        print(f"  Your proxy IP: {r.json()}")
        break
    except requests.exceptions.ProxyError as e:
        err_msg = str(e)
        if "407" in err_msg:
            print(f"  FAILED - 407 Auth Required")
        elif "403" in err_msg:
            print(f"  FAILED - 403 Forbidden")
        else:
            print(f"  FAILED - {err_msg[:100]}")
    except requests.exceptions.ConnectTimeout:
        print(f"  FAILED - Connection timed out")
    except Exception as e:
        print(f"  FAILED - {type(e).__name__}: {str(e)[:100]}")

