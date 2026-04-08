# A10 SSRF

## What it is
SSRF (Server-Side Request Forgery) occurs when attacker-controlled input influences a server-side network request.
The attacker gets to “use the server as a proxy” to reach internal services (admin panels, metadata endpoints, localhost-only APIs)
or to exfiltrate data via outbound requests.

## What it is NOT (common false positives)
- **Not open redirect**: redirects affect browser navigation; SSRF is server-side fetching.
- **Not XSS**: XSS is browser execution; SSRF is backend network access.
- **Not “any outbound HTTP”**: SSRF requires attacker influence over destination (full URL or components).
- **Not fixed by a hostname allowlist alone** if DNS rebinding, redirects, or URL parsing quirks are in play.

## Common variants
- **In-band SSRF**: response body is returned to the attacker.
- **Blind SSRF**: only success/failure is returned (or nothing); impact is still real.
- **Redirect-based SSRF**: initial URL is allowed, but redirects to internal/private targets.
- **DNS rebinding / hostname allowlist bypass**: hostname passes allowlist, but resolves to private IP(s).
- **URL parsing tricks**: userinfo (`https://allowed.com@127.0.0.1/`), IPv6, encoded/decimal IPs, mixed schemes.

Additional common variants:
- **Non-HTTP schemes** accepted by URL fetchers (e.g., `file:`) where supported.
- **Headless browser SSRF** where an attacker controls what pages/resources the browser loads.

## Review checklist (sources → sinks)
Common sources:
- URL fields in APIs: `url`, `callback_url`, `webhook_url`, `avatar_url`, `image_url`, `import_from_url`
- “Preview”, “fetch”, “proxy”, “embed”, “scrape”, “webhook tester” features

Common sinks:
- Python: `requests.get/post`, `urllib.request`, `httpx`, SDK “download from URL” helpers
- Node: `fetch`, `axios`, `request`
- Headless browser/PDF: page loads triggered by attacker-controlled URLs

Controls (defense-in-depth):
- Allowlist **scheme + hostname + (optionally) path prefixes**.
- Resolve DNS and block **private/loopback/link-local/reserved** IP ranges.
- Disable redirects or re-validate every redirect hop.
- Enforce strict `timeout`, limit response size, and restrict ports.
- Prefer network egress controls (firewall/VPC) to block internal ranges.

Also consider:
- Strip/deny userinfo (`user:pass@host`) and normalize URLs before checks.
- Re-validate after following redirects (or disable them).

## Validation notes (safe)
- Prove attacker control over the destination (full URL or components).
- Show the request can reach an internal address/metadata service, or that it can hit arbitrary external hosts.
- For blind SSRF, identify where the request result is observable (logs, metrics, outbound proxy/DNS logs).

## Examples

### In-band SSRF (response returned)

```python
# Vulnerable
@app.route('/fetch-image')
def fetch_image():
    image_url = request.args.get('url')
    return requests.get(image_url).content

# Controlled (hostname allowlist + scheme + timeout; consider redirect handling)
from urllib.parse import urlparse

ALLOWED_DOMAINS = ['images.example.com', 'cdn.example.com']

@app.route('/fetch-image')
def fetch_image():
    image_url = request.args.get('url')
    parsed = urlparse(image_url)
    if parsed.scheme != 'https' or parsed.hostname not in ALLOWED_DOMAINS:
        abort(400, 'Invalid or unauthorized URL')
    return requests.get(image_url, timeout=5, allow_redirects=False).content
```

### Blind SSRF (webhook tester / callback probe)

```python
# Vulnerable (does not return remote response body)
@app.post('/api/webhooks/test')
@require_auth
def test_webhook():
    url = request.json['url']
    requests.post(url, json={'event': 'test'}, timeout=5)
    return {'sent': True}

# Controlled (same allowlist approach; block redirects)
from urllib.parse import urlparse

ALLOWED_WEBHOOK_HOSTS = ['hooks.example.com']

@app.post('/api/webhooks/test')
@require_auth
def test_webhook():
    url = request.json['url']
    parsed = urlparse(url)
    if parsed.scheme != 'https' or parsed.hostname not in ALLOWED_WEBHOOK_HOSTS:
        abort(400, 'Invalid or unauthorized URL')
    requests.post(url, json={'event': 'test'}, timeout=5, allow_redirects=False)
    return {'sent': True}
```

### DNS/IP allowlist hardening (block private/reserved IPs)

```python
# Controlled helper (illustrative; adapt to your platform and threat model)
import ipaddress
import socket
from urllib.parse import urlparse

def hostname_resolves_to_public_ip(hostname: str) -> bool:
    for _, _, _, _, sockaddr in socket.getaddrinfo(hostname, None):
        ip = ipaddress.ip_address(sockaddr[0])
        if (
            ip.is_private
            or ip.is_loopback
            or ip.is_link_local
            or ip.is_multicast
            or ip.is_reserved
        ):
            return False
    return True

def validate_outbound_url(url: str, allowed_hosts: set[str]) -> None:
    parsed = urlparse(url)
    if parsed.scheme != 'https' or parsed.hostname is None:
        raise ValueError('Invalid scheme/host')
    if parsed.hostname not in allowed_hosts:
        raise ValueError('Host not allowed')
    if not hostname_resolves_to_public_ip(parsed.hostname):
        raise ValueError('Host resolves to non-public IP')
```
