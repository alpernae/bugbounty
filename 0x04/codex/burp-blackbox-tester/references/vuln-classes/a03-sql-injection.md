# A03 SQL Injection

## What it is

SQL injection appears when untrusted input is interpreted as SQL syntax instead of data values.

## What it is NOT (common false positives)

- A WAF block page or generic “invalid input” response without any SQL-specific behavioral delta.
- A single transient timeout that doesn’t repeat (network jitter).
- An application error that happens equally for benign inputs (not payload-dependent).

## Black-box probe strategy (Burp MCP)

1. Capture a baseline request that reaches database-backed search, filter, auth, or reporting features.
2. Inject syntax-breaking payloads (`'`, `"`, `)`) and compare error behavior.
3. Test boolean and time-based payloads in parameters that affect query logic.
4. Compare latency and response deltas against baseline to reduce false positives.

Practical Burp tips:

- Keep a baseline Repeater tab and clone it for each payload so headers/cookies stay identical.
- Prefer proving SQLi with **two different techniques** (for example boolean + time) before reporting.
- For timing tests, use small delays (2–3 seconds) and repeat 3–5 times.

## Vulnerable signals

- SQL parser errors in responses or logs exposed to client.
- Authentication bypass with crafted conditions.
- Time-based payloads produce consistent delay deltas.

## Payload ideas (low-impact first)

- Syntax-break: `'` / `"` / `)`
- Boolean split (numeric): `1 AND 1=1` vs `1 AND 1=2`
- Boolean split (string): `' AND '1'='1` vs `' AND '1'='2`
- Time-based examples (DB-specific):
  - MySQL: `SLEEP(2)`
  - PostgreSQL: `pg_sleep(2)`
  - SQL Server: `WAITFOR DELAY '0:0:2'`

Keep payloads minimal and avoid data-exfiltration techniques unless explicitly authorized.

## Example attack request

```http
GET /api/v1/search?term=book'%20OR%201=1-- HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Accept: application/json
```

## Example evidence pattern (boolean-based)

Baseline:

```http
GET /api/v1/search?term=book HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Accept: application/json
```

True condition:

```http
GET /api/v1/search?term=book'%20AND%201=1-- HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Accept: application/json
```

False condition:

```http
GET /api/v1/search?term=book'%20AND%201=2-- HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Accept: application/json
```

If the “false” query reliably returns fewer/no results while the baseline/true query returns results, and the behavior is payload-dependent, SQLi is likely.

## Source code examples

```javascript
// Vulnerable: direct string interpolation into SQL
const query = `SELECT id, title FROM products WHERE title LIKE '%${term}%'`;
const rows = await db.query(query);

// Controlled: parameterized query for untrusted values
const query = 'SELECT id, title FROM products WHERE title LIKE ?';
const rows = await db.query(query, [`%${term}%`]);
```

## Validation notes

- Validate injection impact with at least two payload types (error and boolean or time).
- Ensure timing tests account for network jitter by using repeated measurements.

## Control-level mitigations (no patch code)

- Use parameterized queries/prepared statements for untrusted values.
- Avoid dynamic SQL string concatenation; if unavoidable, strict allowlists for identifiers.
- Apply input validation and output error handling to avoid leaking parser errors.
