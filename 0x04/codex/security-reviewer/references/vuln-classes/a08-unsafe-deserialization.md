# A08 Unsafe Deserialization

## What it is
Unsafe deserialization occurs when untrusted data is deserialized into objects in a way that triggers code execution
or dangerous side effects. It is frequently **RCE**.

## What it is NOT (common false positives)
- **Not JSON parsing** by itself (JSON is typically data-only; the danger comes from how it is used afterward).
- **Not safe just because it is "base64"** (base64 is an encoding; it can still carry unsafe serialized bytes).
- **Not safe because it is signed/encrypted** if the mechanism still reconstructs arbitrary objects (keys leak, replay,
  cross-context reuse, and gadget chains can still apply).

## Common variants
- Python: `pickle.loads` on untrusted input; `yaml.unsafe_load` / `yaml.load` with unsafe loaders.
- Java: native serialization (`ObjectInputStream`) on untrusted streams.
- “Internal only” message buses where attackers can inject payloads.

Additional common variants:
- PHP `unserialize()` on untrusted strings (cookies, cache, queues).
- .NET legacy serializers (e.g., `BinaryFormatter`) on untrusted input.
- YAML/TOML “convenience” loaders that instantiate objects.
- Deserialization in background workers triggered by attacker-controlled messages.

## Review checklist
Look for:
- Any deserialization of attacker-controlled bytes/strings
- Acceptance of serialized blobs from cookies, headers, request bodies, or message queues
- Attempts to “sanitize” rather than remove the unsafe mechanism
- “Signed session” or “encrypted cookie” patterns that still deserialize objects

Controls:
- Prefer data-only formats (JSON) and validate schema.
- Use safe loaders and strict type allowlists.
- If you must deserialize: restrict types, isolate the parser, and treat it as a high-risk boundary.

## Validation notes (safe)
- Prove the application deserializes attacker-controlled input with an unsafe loader.
- Identify the deserialization trigger path (HTTP request, background worker, cache).

## Examples

```python
# Vulnerable
import yaml

def load_system_config(yaml_string):
    return yaml.unsafe_load(yaml_string)

# Controlled
def load_system_config(yaml_string):
    return yaml.safe_load(yaml_string)
```

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

```java
// Vulnerable pattern (illustrative)
ObjectInputStream ois = new ObjectInputStream(request.getInputStream());
Object obj = ois.readObject();

// Controlled approach
// Use JSON + schema validation, or a serializer with strict allowlists.
```
