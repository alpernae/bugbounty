# A03 NoSQL Injection

## What it is

NoSQL injection happens when attacker-controlled input is interpreted as part of a NoSQL query (operators/selectors) instead of being treated as data.

A common case is MongoDB-style query injection where the server accepts JSON objects (or nested query parameters) and merges them into a database filter without strict schema validation.

## What it is NOT (common false positives)

- A strict schema/type rejection (for example `400 invalid payload`) with no query behavior change.
- A search feature that accepts regex-like strings **as strings** (no operator/object injection).
- Pure authorization bugs (IDOR/BOLA) where cross-tenant data is returned because of missing ownership checks rather than query manipulation.

## Where it shows up

- Login endpoints that accept JSON bodies.
- Search/filter endpoints that accept a JSON `filter` / `where` object.
- Query-string parsers that build objects from nested parameters (for example `field[$ne]=x`).
- “Advanced filter” UI features that submit structured filters.

## Black-box probe strategy (Burp MCP)

Precondition: pick an endpoint that likely builds a DB query from user input (search, filter, login, lookup).

1. Capture a baseline request with a known-good value and stable response.
2. Try **operator injection** patterns while keeping everything else identical:
   - Replace a string field with an object containing an operator.
   - For query strings, try nested-parameter forms.
3. Compare baseline vs attack responses (status, body size, fields returned, result counts).
4. If the target is authentication/authorization relevant, do a two-step proof:
   - show the bypass (for example login succeeds), then
   - show a privileged effect (for example access to `/me`, session cookie issued).

Keep probes low-impact. Avoid destructive update operators unless explicitly authorized and you can do it against a test object.

## Vulnerable signals

- Authentication bypass (login success with invalid credentials).
- Expanded result set (filters that should narrow results instead return “everything”).
- Errors referencing query operators or NoSQL engine behavior.
- A measurable behavioral delta that is operator-dependent (not just generic input validation).

## Example attack request (login bypass style)

Baseline (expected failure with wrong password):

```http
POST /api/login HTTP/1.1
Host: app.example.test
Content-Type: application/json

{"username":"alice@example.test","password":"wrong"}
```

Attack (operator injection attempting to match any user):

```http
POST /api/login HTTP/1.1
Host: app.example.test
Content-Type: application/json

{"username":{"$ne":null},"password":{"$ne":null}}
```

If the attack produces a session cookie/token and `/api/me` confirms an authenticated identity, exploitability is proven.

## Example attack request (nested query parameter form)

Some stacks parse nested query strings into objects. Example hypothesis:

```http
GET /api/v1/users?email%5B%24ne%5D=x HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Accept: application/json
```

If this turns a strict lookup into a broad match, it’s a strong NoSQLi indicator.

## Source code examples

```javascript
// Vulnerable: user-controlled object becomes the database filter
// (common anti-pattern in Node/Mongoose)
const user = await Users.findOne(req.body);

// Controlled: strict allowlist + type enforcement before building a query
const username = String(req.body.username ?? "");
const password = String(req.body.password ?? "");
const user = await Users.findOne({ username, passwordHash: hash(password) });
```

```python
# Vulnerable: request JSON used directly as filter (PyMongo)
user = users.find_one(request.json)

# Controlled: build filter from explicit, type-checked fields
username = str(request.json.get("username", ""))
user = users.find_one({"username": username})
```

## Validation notes

- Prove the delta is operator-driven by testing at least two variants (for example `$ne` and `$gt`).
- Confirm you’re not observing an unrelated parsing error (compare with benign malformed JSON).
- For auth bypass claims, always validate via a second endpoint (`/me`, account page) to avoid “success-shaped error” responses.

## Control-level mitigations (no patch code)

- Enforce strict schema validation (type checks) and reject objects where strings are expected.
- Disallow or strip query operator keys (commonly keys starting with `$`) from untrusted input.
- Build database filters from explicit allowlisted fields rather than merging user-supplied objects.
- Add monitoring for anomalous operator usage and authentication bypass attempts.
