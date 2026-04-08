# Zero Trust: Never Trust Internal Requests

## What it is

Zero Trust assumes the network is hostile: “internal” requests can be forged, proxied, or replayed.
Internal APIs must enforce strong authentication, authorization, and input validation just like public endpoints.

## What it is NOT (common false positives)

- Not solved by source IP checks alone: IPs can be spoofed, proxied, or reached via SSRF/misrouting.
- Not solved by a magic header like `X-Internal-Request: true`.
- Not only HTTP: the same principle applies to queues, event buses, gRPC, and storage triggers.

## Black-box probe strategy (Burp MCP)

1. Identify “internal/admin” endpoints and assumptions:
   - endpoints that return “internal only” messaging,
   - admin panels, debug routes, health checks,
   - service-to-service APIs reachable via the same domain.
2. Attempt direct access with a normal user session; confirm access is denied.
3. Test header-trust bypasses by adding common “internal” or proxy headers:
   - `X-Internal-Request: true`
   - `X-Forwarded-For: 127.0.0.1`
   - `X-Forwarded-Host`, `X-Original-URL`, `X-Rewrite-URL`
4. If you have an SSRF hypothesis, attempt to reach internal endpoints only if it is in-scope and explicitly allowed.

Practical Burp tips:

- Keep baseline and attack requests identical except for the header under test.
- Repeat the test (3/3) to reduce false positives.

## Vulnerable signals

- Access is granted or behavior changes only when “internal” headers are present.
- Admin-only actions can be invoked from a user context.
- Responses contain “trusted subnet” or “internal request” handling paths.

## Example attack request

```http
GET /internal/admin/stats HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
X-Internal-Request: true
```

## Source code examples

```python
# Vulnerable (illustrative)
if request.headers.get('X-Internal-Request') == 'true':
    return admin_action()

# Controlled (illustrative)
# Require strong service identity (mTLS/JWT) + explicit authorization
require_service_auth()
require_authorization('admin_action')
return admin_action()
```

## Validation notes

- Only report when you can show a concrete boundary bypass (not just header reflection).
- Be explicit about the boundary crossed: user → admin, public → internal, tenant A → tenant B.

## Control-level mitigations (no patch code)

- Enforce service-to-service authentication (mTLS or signed service tokens).
- Do not make authorization decisions based on client-settable headers.
- Add replay protection and short-lived credentials for internal calls.
- Audit internal admin operations and apply least privilege.
