# Reliability with Security Impact: External Calls

## What it is

Unreliable external calls can become security issues: attackers can induce hangs, retry storms, and resource exhaustion.
Missing timeouts and weak TLS settings can also increase exposure.

## What it is NOT (common false positives)

- A single failed request is not inherently a security issue; the risk is systemic (exhaustion, amplification, fail-open).
- This is not just “performance tuning”: reliability controls often prevent DoS and reduce blast radius.
- Not solved by broad error handling that hides failures (that can make recovery and detection worse).

## Black-box probe strategy (Burp MCP)

1. Identify endpoints likely to call external services:
   - OAuth/token exchange, payment flows, email/SMS sends,
   - “import from URL”, link previews, webhook delivery tests,
   - integrations pages that validate credentials.
2. Capture a baseline request and measure typical response time.
3. Test timeout behavior safely:
   - provide an unreachable destination (when the feature accepts a URL/host),
   - or trigger an external dependency that is known to respond slowly in your test environment.
4. Observe whether the request fails fast with a clear error or ties up the connection for a long time.
5. If the system makes outbound calls to your controlled domain, use Burp Collaborator to detect:
   - repeated retries,
   - unexpected parallelism,
   - missing destination validation (SSRF adjacency).

Practical Burp tips:

- Use unique per-request IDs in the URL path so you can correlate retries in Collaborator.
- Keep tests low volume; one request that hangs for 2 minutes is a finding.

## Vulnerable signals

- Requests hang for a long time (no timeout) and consume client/server concurrency.
- A single inbound request triggers many outbound retries/calls (amplification).
- External calls appear to be made to attacker-influenced destinations without validation (SSRF adjacency).

## Example evidence pattern

- Baseline: request completes in < 1 second.
- Attack: same request with an unreachable upstream blocks for > 30 seconds or until client timeout.

## Source code examples

```python
# Vulnerable
response = requests.get(api_url)

# Controlled (illustrative)
for attempt in range(3):
    try:
        response = requests.get(api_url, timeout=30, verify=True)
        if response.status_code == 200:
            break
    except requests.RequestException:
        time.sleep(2 ** attempt)
```

## Validation notes

- Confirm the slow/hanging behavior is tied to attacker-controlled input (destination/parameters), not generic load.
- If possible, demonstrate concurrency impact (for example, multiple requests queue behind the hang).

## Control-level mitigations (no patch code)

- Set conservative timeouts; cap retries with exponential backoff.
- Add circuit breakers/bulkheads for fragile dependencies.
- Validate destinations when URLs/hosts are user-influenced.
- Stream and bound response sizes for downloads.
