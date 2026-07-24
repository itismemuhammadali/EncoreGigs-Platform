import requests
from urllib.parse import quote

password = "v6Uyj0_zhW77iNlIvx"
encoded_password = quote(password, safe="")

tests = [
    ("Plain password 10001", f"http://ONLYGIGZ:{password}@gate.decodo.com:10001"),
    ("Encoded password 10001", f"http://ONLYGIGZ:{encoded_password}@gate.decodo.com:10001"),
    ("Plain password 10002", f"http://ONLYGIGZ:{password}@gate.decodo.com:10002"),
    ("Encoded password 10002", f"http://ONLYGIGZ:{encoded_password}@gate.decodo.com:10002"),
    ("Plain password 10003", f"http://ONLYGIGZ:{password}@gate.decodo.com:10003"),
    ("Encoded password 10003", f"http://ONLYGIGZ:{encoded_password}@gate.decodo.com:10003"),
]

for label, proxy_url in tests:
    proxies = {"http": proxy_url, "https": proxy_url}
    print(f"\n{label}")
    try:
        r = requests.get("https://httpbin.org/ip", proxies=proxies, timeout=10)
        print(f"  SUCCESS - {r.json().get('origin', '?')}")
        break
    except requests.exceptions.ProxyError as e:
        err = str(e)
        if "407" in err:
            print(f"  407 Auth Required")
        else:
            print(f"  FAIL: {err[:80]}")
    except Exception as e:
        print(f"  FAIL: {str(e)[:80]}")
