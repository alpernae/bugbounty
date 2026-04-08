# Reliability with Security Impact: Resource Exhaustion

## What it is
Resource exhaustion occurs when attackers can trigger excessive CPU, memory, file descriptors, or disk usage.
It often shows up as “reliability” bugs but can be exploited for DoS or to bypass rate limits.

## What it is NOT (common false positives)
- Normal high traffic is not a “resource exhaustion vulnerability” unless an attacker can drive disproportionate cost.
- A slow endpoint is not necessarily exploitable unless input controls allow amplification.
- Not only about file uploads; many small inputs can trigger expensive work (regex, parsing, fan-out).

## Common variants
- Reading unbounded request bodies or files into memory.
- Decompression bombs, unbounded recursion, expensive regex.
- Unbounded concurrency (queue growth, fan-out).

Additional common variants:
- Image/PDF processing without size/complexity limits.
- Zip/tar extraction without total-size limits.
- Hash/regex “algorithmic complexity” attacks.
- LLM usage without token limits or per-user quotas (cost/latency DoS).

## Review checklist
Look for:
- `.read()` on potentially large inputs
- Missing size limits, missing streaming, missing backpressure
- Hot paths that do per-request heavy parsing/crypto without limits

Also look for:
- Fan-out patterns (one request triggers N downstream calls).
- Background queues that can grow unbounded.
- Endpoints that scale superlinearly with attacker-controlled input.

Controls:
- Stream data, enforce max sizes, and apply backpressure.
- Add per-user and global rate limits on expensive endpoints.
- Enforce timeouts and cancellation on expensive work.
- Limit recursion depth and regex complexity.

## Validation notes (safe)
- Identify attacker-controlled inputs that can scale resource usage superlinearly.

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
