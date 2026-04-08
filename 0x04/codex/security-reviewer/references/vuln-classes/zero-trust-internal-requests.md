# Zero Trust: Never Trust Internal Requests

## What it is
Zero Trust assumes the network is hostile: “internal” requests can be forged or replayed.
Internal APIs must enforce strong authentication, authorization, and input validation just like public endpoints.

## What it is NOT (common false positives)
- **Not “only an ops concern”**: application code must enforce identity/authorization; network controls are defense-in-depth.
- **Not solved by source IP checks alone**: IPs can be spoofed, proxied, or reached via SSRF/misrouting.
- **Not solved by a magic header** like `X-Internal-Request: true`.
- **Not only HTTP**: the same principle applies to queues, event buses, gRPC, and storage triggers.

## Common variants
- Internal endpoints reachable from user-controlled paths (SSRF, misrouted proxies, exposed admin ports).
- Implicit trust based on source IP / VPC / headers like `X-Internal-Request: true`.
- Background workers consuming untrusted messages without authentication.

Additional common variants:
- Shared “internal” API keys reused across environments.
- Missing replay protection (long-lived tokens, no nonce/timestamp).
- Internal-only endpoints that perform admin actions with no authorization checks.

## Review checklist
Look for:
- Internal handlers without service auth tokens / mTLS
- “Trusted subnet” assumptions
- Missing schema validation on internal message payloads

Also look for:
- Authorization decisions based on headers set by clients (or by edge services that can be bypassed).
- Message consumers that assume the producer is trusted (no signature/identity).
- Lack of auditing on internal admin operations.

Controls:
- Service-to-service authentication (mTLS, signed JWTs, rotating service tokens).
- Explicit allowlists for caller identity + least privilege authorization.
- Replay protection (short-lived tokens, nonce/timestamp where appropriate).
- Treat internal inputs as untrusted: validate schemas strictly.

## Validation notes (safe)
- Identify any path where untrusted traffic can reach internal handlers (ingress misconfig, SSRF, message bus injection).

```python
# Vulnerable
def internal_api(data):
    return process(data)

# Controlled
def internal_api(data, auth_token):
    if not verify_service_token(auth_token):
        raise UnauthorizedError()
    if not validate_request(data):
        raise ValidationError()
    return process(data)
```
