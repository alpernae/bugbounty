# A08 Unsafe Deserialization

## What it is

Unsafe deserialization occurs when untrusted data is deserialized into objects in a way that triggers code execution
or dangerous side effects. It is frequently remote code execution (RCE).

## What it is NOT (common false positives)

- Not JSON parsing by itself (JSON is typically data-only; the danger comes from deserializing objects with behavior).
- Not safe just because it is “base64” (base64 is an encoding; it can still carry unsafe serialized bytes).
- Not safe because it is signed/encrypted if the system still reconstructs arbitrary objects.

## Black-box probe strategy (Burp MCP)

Black-box validation focuses on proving a deserialization sink exists and that attacker-controlled bytes reach it.

1. Identify candidate inputs that may carry serialized objects:
   - unusual content types (`application/octet-stream`, `application/x-java-serialized-object`),
   - upload/import endpoints,
   - cookies/headers/params containing large opaque base64 blobs,
   - PHP-like serialized strings (often starting with `O:` or `a:`) or Java/.NET binary blobs.
2. Capture a baseline request that succeeds.
3. Perform a minimal corruption test:
   - flip one character in the blob (or one byte for binary),
   - resend the request,
   - observe whether the failure mode indicates deserialization (not just “invalid input”).
4. Look for deserialization-specific error signals (stack traces, exception names, log messages exposed to the client).
5. If the feature is “internal only” (queues/webhooks), treat it as a hypothesis unless you can prove untrusted input can reach it.

Practical Burp tips:

- Prefer one small mutation over large fuzzing.
- Avoid repeated, large payloads that could cause DoS.

## Vulnerable signals

- Errors referencing known deserialization mechanisms, for example:
  - Java: `StreamCorruptedException`, `invalid stream header`, `ObjectInputStream`
  - Python: `pickle.UnpicklingError`
  - PHP: `unserialize(): Error at offset`
  - .NET: `BinaryFormatter` (legacy)
- The server accepts attacker-influenced object types/graphs (rare to prove safely from black-box).

## Example evidence pattern

Baseline:

```http
GET /api/v1/profile HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Cookie: prefs=<redacted>
```

Mutated cookie (single-character change):

```http
GET /api/v1/profile HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Cookie: prefs=<redacted-mutated>
```

If the mutated request reliably triggers a response mentioning a deserialization-specific exception, you have strong evidence of a deserialization sink.

## Source code examples

```python
# Vulnerable
import pickle

def load_session(blob: bytes):
    return pickle.loads(blob)

# Controlled
import json

def load_session(blob: bytes):
    return json.loads(blob.decode('utf-8'))
```

## Validation notes

- The highest-confidence claim from black-box is often “unsafe deserialization sink is present”.
- Avoid claiming exploitability (RCE) unless you can demonstrate a concrete impact safely and in-scope.
- If stack traces are not exposed, look for consistent behavioral differences that only occur when a blob is malformed.

## Control-level mitigations (no patch code)

- Prefer data-only formats (JSON) and validate schema.
- Avoid unsafe object deserializers for untrusted inputs.
- If deserialization is unavoidable, enforce strict type allowlists and isolate the parser.
- Ensure integrity checks fail closed before any deserialization occurs.
