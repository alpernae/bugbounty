# How Burp MCP Works

## High-level model

Burp MCP connects an AI assistant to Burp Suite capabilities so testing can be run as a repeatable workflow instead of one-off clicks.

Typical loop:

1. Pull traffic context (site map, proxy history, discovered endpoints).
2. Pick a concrete hypothesis (for example: IDOR on `/api/v1/invoices/{id}`).
3. Build a baseline request and a single “attack variant” request.
4. Replay both under the same auth context and compare status, headers, body, and side effects.
5. Repeat with at least one alternate payload/variant to reduce false positives.
6. Write up only what you can reproduce.

## What you can ask Burp for (conceptually)

Exact capability depends on how your Burp MCP server is configured, but the common building blocks are:

- Observed requests/responses (proxy history) and a derived site map.
- Parsed parameters (query, JSON, form, cookies, headers) to target mutations.
- Request replay (Repeater-style) under the same session context.
- Optional helpers such as out-of-band interaction logging (Collaborator-style) or concurrency primitives.

If a capability is unavailable, fall back to Burp UI actions and paste the raw HTTP evidence back into the thread.

## Practical workflow (black-box)

### 0) Engagement setup

- Confirm scope and safety constraints (.github/SCOPE.md when present).
- Confirm base URLs, roles/accounts you can use, and what actions are allowed.
- Set limits: request rate, lockout policy, brute-force constraints, and destructive-action policy.
- Verify session handling: cookie vs bearer token, CSRF token location, and token refresh behavior.

### 1) Surface mapping

- Build an endpoint inventory from captured traffic and the site map.
- Group endpoints by auth context and trust boundary (anonymous / user / admin / internal-only).
- Tag high-risk operations: auth, money movement, exports, file handling, webhooks, URL fetchers.

### 2) Hypothesis-driven testing

Prefer targeted probes over broad fuzzing.

Good default hypotheses to test across most apps:

- Access control: IDOR/BOLA, function-level authorization, tenant isolation.
- Injection: SQLi/NoSQLi, XSS where applicable.
- Workflow abuse and races: TOCTOU, stale-step replay, out-of-order operations.
- CSRF: cookie-authenticated state changes.
- SSRF: server-side URL fetch behavior.

### 3) Validation and evidence

For each confirmed issue:

- Capture baseline + attack requests (raw HTTP).
- Capture response excerpts that prove the control failure (or side-effect evidence).
- Record role, preconditions, exploit reliability, and limitations.
- Include at least one “false-positive elimination” check (alternate ID, alternate payload, repeat run).

## Example probe loops

### Object-level authorization (IDOR/BOLA)

- Baseline: `GET /resource/{id}` as User A.
- Attack: swap `{id}` to an object owned by User B.
- Proof: response contains B’s data, or an update/delete/action succeeds.

### SQLi quick triage

- Baseline: pick a stable query parameter (search/filter).
- Attack 1: syntax-break (`'`) to observe controlled vs error behavior.
- Attack 2: boolean split (true vs false) to confirm a response delta.
- Attack 3 (optional): low-delay time-based payload (2–3s) repeated 3–5 times.

### SSRF

- Baseline: fetch a benign external URL you control.
- Attack: try loopback/RFC1918/metadata IPs (low-impact).
- Proof: internal content is returned, or an out-of-band callback proves a server-side fetch.

## Evidence quality checklist

For each validated finding, capture:

- Target endpoint and method.
- Baseline request and attack request (include headers/cookies only as needed).
- Key response delta proving bypass/unsafe behavior.
- Required preconditions (role, tenant, account state).
- Exploit reliability (how often it reproduces) and limitations.

## Safety guardrails

- Stay inside declared scope.
- Start low-impact; escalate only when necessary to prove exploitability.
- Avoid irreversible actions unless explicitly authorized.
- Redact tokens, credentials, and personal data in evidence.
- Prefer test environments/accounts when available.
