import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend", ".env"))

import requests

url = "https://www.eventbrite.com/d/tx--austin/music--events/"
headers = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
}

for port in [10001, 10002, 10003, 10004, 10005, 10006, 10007]:
    proxy_url = f"http://gate.decodo.com:{port}"
    proxies = {"http": proxy_url, "https": proxy_url}
    try:
        r = requests.get(url, headers=headers, proxies=proxies, timeout=15)
        print(f"Port {port}: {r.status_code} | {len(r.text)} bytes")
        if r.status_code == 200 and len(r.text) > 10000:
            print(f"  SUCCESS! Content looks real.")
            break
    except Exception as e:
        print(f"Port {port}: FAIL | {str(e)[:60]}")
