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

proxy_url = f"http://OG:{api_key}@gate.smartproxy.com:7777"
proxies = {"http": proxy_url, "https": proxy_url}

print(f"Testing proxy: OG@gate.smartproxy.com:7777 ...")
try:
    r = requests.get("https://httpbin.org/ip", proxies=proxies, timeout=20)
    print(f"SUCCESS - Status: {r.status_code}")
    print(f"Your proxy IP: {r.json().get('origin', 'unknown')}")
except requests.exceptions.ConnectTimeout:
    print("FAILED - Connection timed out")
    print("Possible causes:")
    print("  1. IP not whitelisted in SmartProxy dashboard")
    print("  2. Wrong proxy format (may need sub-user instead of 'user')")
    print("  3. SmartProxy account not active")
except requests.exceptions.ProxyError as e:
    print(f"FAILED - Proxy error: {e}")
    print("Possible causes:")
    print("  1. Key may be an API key, not a proxy password")
    print("  2. Account may need IP whitelisting")
except Exception as e:
    print(f"FAILED - {type(e).__name__}: {e}")
