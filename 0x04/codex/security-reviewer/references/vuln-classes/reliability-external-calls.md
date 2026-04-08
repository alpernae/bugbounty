# Reliability with Security Impact: External Calls

## What it is
Unreliable external calls can become security issues: attackers can induce hangs, retries storms, and resource exhaustion.
Missing timeouts and weak TLS settings also increase exposure.

## What it is NOT (common false positives)
- A single failed request is not inherently a security issue; the risk is systemic (exhaustion, amplification, fail-open).
- This is not just “performance tuning”: reliability controls often prevent DoS and reduce blast radius.
- Not solved by broad `try/except` that hides errors (that can make recovery and detection worse).

## Common variants
- No timeout → thread/worker exhaustion (DoS).
- Infinite/unsafe retries → amplification and self-DoS.
- TLS verification disabled.
- No circuit breakers/bulkheads in high-traffic paths.

Additional common variants:
- Fetching attacker-influenced URLs (SSRF adjacency) without destination validation.
- Downloading unbounded responses into memory/disk.
- Missing connection pool limits (exhausting file descriptors/sockets).

## Review checklist
Look for:
- `requests.get(url)` without `timeout`
- Broad exception handling that hides failures
- Retry loops without caps/backoff/jitter

Also look for:
- Calls inside request handlers without concurrency limits.
- Retries on non-idempotent operations.
- TLS settings changed globally (e.g., disabling verification).

Controls:
- Set timeouts, cap retries, add exponential backoff, and fail fast.
- Validate destinations when URLs are user-influenced (SSRF adjacency).
- Add circuit breakers/bulkheads for high-traffic or fragile dependencies.
- Bound response sizes and stream large bodies.

## Validation notes (safe)
- Identify critical request paths where a slow upstream can exhaust concurrency.

```python
# Vulnerable
response = requests.get(api_url)

# Controlled
for attempt in range(3):
    try:
        response = requests.get(api_url, timeout=30, verify=True)
        if response.status_code == 200:
            break
    except requests.RequestException as error:
        logger.warning(f'Attempt {attempt + 1} failed: {error}')
        time.sleep(2 ** attempt)
```
