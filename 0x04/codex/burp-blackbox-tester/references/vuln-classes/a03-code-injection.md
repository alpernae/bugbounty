# A03 Code Injection

## What it is

Code injection happens when untrusted input is treated as code (or a code-like expression) and executed by an interpreter/runtime.
In practice this can become remote code execution (RCE) or sensitive data access.

## What it is NOT (common false positives)

- Not SQL injection: SQLi changes database queries via SQL sinks.
- Not command injection: command injection abuses OS command execution.
- Not SSTI by default: SSTI is a specific case where untrusted templates are rendered server-side.
- Not “dynamic behavior” when inputs are mapped through strict allowlists (capabilities selected, not code executed).

## Black-box probe strategy (Burp MCP)

1. Identify candidate inputs that look like they could be evaluated:
   - `expression`, `expr`, `formula`, `filter`, `rule`, `condition`, `script`, `template`, `mapping`.
2. Capture a baseline request where the value is treated as data.
3. Use harmless evaluation probes to detect server-side execution without attempting RCE:
   - arithmetic evaluation (does `7*7` become `49`?),
   - error forcing (does an invalid expression produce a distinct evaluation error?).
4. If the feature is stored/blind (saved rule executed later), trigger the downstream action and observe output.

Practical Burp tips:

- Prefer “proof of evaluation” over “we think it’s eval”.
- Stop at a minimal proof. Do not attempt OS commands or file reads unless explicitly authorized.

## Vulnerable signals

- The server returns evaluated output (for example, returns `49` when given `7*7`).
- The server returns evaluation/compilation errors that reference an expression engine.
- The behavior changes only when the expression is changed (payload-dependent).

## Example evidence pattern

Baseline (literal string):

```http
POST /api/v1/rules/test HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Content-Type: application/json

{"expression":"7*7"}
```

If the response contains `49` (or otherwise demonstrates server-side evaluation), that is strong evidence of an execution sink.

## Source code examples

```python
# Vulnerable
@app.get('/api/calc')
@require_auth
def calc():
    expr = request.args['expr']
    return {'result': eval(expr)}

# Controlled (treat input as data; allowlist operations)
ALLOWED_OPS = {
    'add': lambda a, b: a + b,
    'sub': lambda a, b: a - b,
}

@app.post('/api/calc')
@require_auth
def calc():
    op = request.json['op']
    a = int(request.json['a'])
    b = int(request.json['b'])
    fn = ALLOWED_OPS.get(op)
    if fn is None:
        abort(400, 'Unsupported operation')
    return {'result': fn(a, b)}
```

## Validation notes

- Confirm the evaluation occurs server-side (in the HTTP response), not in client-side UI code.
- Capture baseline vs attack requests and show a clear, reproducible delta.
- If you cannot demonstrate evaluation, report it as a hypothesis and list what evidence is missing.

## Control-level mitigations (no patch code)

- Treat user input as data, not code.
- If a DSL is required, implement a strict parser and allowlist evaluator (no arbitrary functions/imports).
- Isolate unavoidable untrusted evaluation in a sandbox with no secrets and restricted egress.
