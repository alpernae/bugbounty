# A10 SSRF

## What it is

SSRF happens when a server fetches attacker-supplied URLs and can be tricked into reaching internal or privileged network locations.

## What it is NOT (common false positives)

- A client-side redirect or browser-side fetch (prove the server initiated the request).
- A URL parameter that is validated and only used as display text (no fetch).
- A blocked connection where all targets behave the same way (need a destination-dependent delta).

## Black-box probe strategy (Burp MCP)

1. Identify URL-fetch features (preview, import, webhook test, media fetch, PDF renderers).
2. Send external benign URLs first, then probe internal targets (`127.0.0.1`, RFC1918 ranges, metadata IPs).
3. Observe response body, headers, status changes, and timing differences.
4. Use out-of-band interaction channels when direct responses are suppressed.

Practical Burp tips:

- Start with a URL you control so you can prove the server fetched it.
- Watch for redirects: if the server follows redirects, test whether you can redirect to internal targets.
- If responses are suppressed, use an out-of-band callback channel (Collaborator-style) and report what evidence proves server-side fetch.

## Vulnerable signals

- Internal service content returned to attacker.
- Response differences indicate internal host reachability.
- External callback logs show server-originated requests to attacker-controlled endpoint.

## Example evidence pattern

- Baseline: server fetches `https://oob.example.test/ping` and you observe a hit from the target’s IP range.
- Attack: server also fetches `http://127.0.0.1:...` (or makes a second internal request) and behavior changes (timing/status/body).

## Example attack request

```http
POST /api/v1/url-preview HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Content-Type: application/json

{"url":"http://169.254.169.254/latest/meta-data/"}
```

## Source code examples

```python
# Vulnerable: arbitrary URL fetch without destination controls
def fetch_preview(url):
    return requests.get(url, timeout=4).text

# Controlled: strict allowlist with protocol and host validation
def fetch_preview(url):
    parsed = parse_and_validate_url(url)
    enforce_allowlisted_host(parsed.hostname)
    enforce_scheme(parsed.scheme, allowed={"https"})
    return requests.get(parsed.geturl(), timeout=4).text
```

## Validation notes

- Prove server-side behavior, not client-only redirects.
- Distinguish DNS-only callbacks from full HTTP fetches when rating impact.

## Control-level mitigations (no patch code)

- Enforce allowlists for destinations (scheme + host + port) and block internal ranges.
- Resolve DNS and validate IPs after redirects (and re-validate on every hop).
- Run fetchers in a constrained network environment with egress controls.
