"""Quick test to verify Decodo proxy connectivity."""
import requests

proxy_url = "http://ONLYGIGZ:v6Uyj0_zhW77iNlIvx@gate.decodo.com:10001"
proxies = {"http": proxy_url, "https": proxy_url}

print(f"Testing proxy: ONLYGIGZ@gate.decodo.com:10001 ...")
try:
    r = requests.get("https://ip.decodo.com/json", proxies=proxies, timeout=15)
    print(f"SUCCESS - Status: {r.status_code}")
    print(f"Your proxy IP: {r.json()}")
except requests.exceptions.ProxyError as e:
    print(f"FAILED - Proxy error: {e}")
except requests.exceptions.ConnectTimeout:
    print("FAILED - Connection timed out")
except Exception as e:
    print(f"FAILED - {type(e).__name__}: {e}")
