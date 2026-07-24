import requests
from requests.auth import HTTPBasicAuth

password = "v6Uyj0_zhW77iNlIvx"

tests = [
    ("BasicAuth ONLYGIGZ", "ONLYGIGZ", password),
    ("BasicAuth OG", "OG", password),
]

for label, user, passw in tests:
    print(f"\n{label}")
    
    # Method 1: Proxy dict with tuple
    proxies = {"http": f"http://gate.decodo.com:10001", "https": f"http://gate.decodo.com:10001"}
    try:
        r = requests.get("https://httpbin.org/ip", proxies=proxies, auth=HTTPBasicAuth(user, passw), timeout=10)
        print(f"  BasicAuth tuple: SUCCESS - {r.json().get('origin', '?')}")
    except requests.exceptions.ProxyError as e:
        if "407" in str(e): print(f"  BasicAuth tuple: 407")
        else: print(f"  BasicAuth tuple: {str(e)[:60]}")
    except Exception as e:
        print(f"  BasicAuth tuple: {str(e)[:60]}")
    
    # Method 2: ProxyConnect tunnel
    import http.client
    try:
        conn = http.client.HTTPSConnection("gate.decodo.com", 10001, timeout=10)
        conn.set_tunnel("httpbin.org", 443)
        import base64
        creds = base64.b64encode(f"{user}:{passw}".encode()).decode()
        conn.request("GET", "/ip", headers={"Proxy-Authorization": f"Basic {creds}"})
        r = conn.getresponse()
        print(f"  ProxyConnect: {r.status} {r.read(100)}")
    except Exception as e:
        print(f"  ProxyConnect: {str(e)[:60]}")

