import requests

password = "v6Uyj0_zhW77iNlIvx"

tests = [
    ("ONLYGIGZ + pass", f"http://ONLYGIGZ:{password}@gate.decodo.com:10001"),
    ("OG + pass", f"http://OG:{password}@gate.decodo.com:10001"),
    ("user-ONLYGIGZ + pass", f"http://user-ONLYGIGZ:{password}@gate.decodo.com:10001"),
    ("ONLYGIGZ + pass port 10002", f"http://ONLYGIGZ:{password}@gate.decodo.com:10002"),
    ("OG + pass port 10002", f"http://OG:{password}@gate.decodo.com:10002"),
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
            print(f"  407")
        elif "403" in err:
            print(f"  403")
        else:
            print(f"  FAIL: {err[:60]}")
    except Exception as e:
        print(f"  FAIL: {str(e)[:60]}")
