# Reliability with Security Impact: Resource Exhaustion

## What it is

Resource exhaustion occurs when attackers can trigger excessive CPU, memory, file descriptors, or disk usage.
It often shows up as “reliability” bugs but can be exploited for denial-of-service (DoS) or to bypass rate limits.

## What it is NOT (common false positives)

- Normal high traffic is not a “resource exhaustion vulnerability” unless an attacker can drive disproportionate cost.
- A slow endpoint is not necessarily exploitable unless input controls allow amplification.
- Not only about file uploads; many small inputs can trigger expensive work (regex, parsing, fan-out).

## Black-box probe strategy (Burp MCP)

Prefer safe, incremental validation. Avoid uncontrolled stress testing.

1. Identify expensive-looking endpoints:
   - search/filter with complex parameters,
   - report/export generation,
   - file uploads, image/PDF processing,
   - endpoints that trigger background jobs,
   - AI/LLM endpoints with large prompts.
2. Capture a baseline request and response time.
3. Increase input size/complexity gradually (small steps):
   - slightly larger request bodies,
   - nested JSON arrays/objects,
   - longer strings.
4. Observe for missing limits:
   - no `413`/validation errors,
   - long processing times,
   - memory-related failures (`500`, connection resets),
   - increased latency for unrelated endpoints (blast radius).
5. If the application supports concurrency controls, verify they exist (rate limits, job queues, per-user quotas).

Practical Burp tips:

- Use Intruder responsibly (low thread count, small request counts).
- Record exact payload sizes and timing deltas.

## Vulnerable signals

- The server accepts unbounded inputs and performs expensive work without limits.
- Small attacker-controlled inputs cause large server-side amplification (fan-out).
- Resource-heavy endpoints are missing rate limits or per-user quotas.

## Example evidence pattern

- Baseline: 2 KB request completes in ~200 ms.
- Attack: 200 KB request (same endpoint) takes 30+ seconds or fails with `500`.

## Source code examples

```python
# Vulnerable
def process_large_file(filepath):
    with open(filepath, 'r') as file_handle:
        data = file_handle.read()
    return analyze(data)

# Controlled
def process_large_file(filepath):
    results = []
    with open(filepath, 'r') as file_handle:
        for line in file_handle:
            results.append(analyze_line(line))
    return results
```

## Validation notes

- Keep inputs within agreed safety limits.
- Prefer demonstrating “disproportionate cost” rather than full outage.
- If possible, reproduce at least twice to rule out transient infrastructure issues.

## Control-level mitigations (no patch code)

- Enforce request size and complexity limits.
- Stream large bodies and apply backpressure.
- Add rate limits/quotas for expensive endpoints.
- Enforce timeouts and cancellation for long-running work.
