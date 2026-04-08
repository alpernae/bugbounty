# GraphQL security pitfalls (black-box)

## What it is

GraphQL is a query language, not a vulnerability class by itself. Security issues usually come from:

- missing authorization in resolvers,
- missing field-level policy,
- excessive schema/error exposure,
- denial of service via expensive queries.

## What it is NOT (common false positives)

- Introspection enabled alone is not automatically exploitable; treat it as a **risk amplifier** and validate what it enables.
- “CORS is permissive” is not the same thing as CSRF protection being absent (CSRF can still exist with strict CORS).
- A GraphQL error message that reveals a field name is typically low severity unless it enables targeted exploitation.

## Where it shows up

- A single endpoint, commonly `POST /graphql` (sometimes `/api/graphql`).
- Batched requests (JSON array) if the server supports query batching.
- File upload GraphQL flows (multipart requests).
- Subscriptions over WebSockets.

## Black-box probe strategy (Burp MCP)

### 1) Identify the GraphQL endpoint

- Look for requests with a JSON body containing `query`, `operationName`, and `variables`.
- Common content types: `application/json` or `application/graphql`.

### 2) Map the schema (if permitted)

- Try an introspection query.
- If introspection is disabled, infer types/fields from error messages and observed traffic.

### 3) Test object-level authorization (BOLA/IDOR in resolvers)

- Find queries that fetch objects by id (`node(id: ...)`, `user(id: ...)`, `invoice(id: ...)`).
- Use two accounts (User A, User B) and attempt to fetch B’s objects as A.

### 4) Test field-level authorization

- Request sensitive fields that should be restricted (email, roles, billing, PII).
- Validate that the server enforces policy per field, not just per object.

### 5) Test mutation authorization

- Identify mutations that change state (disable users, change roles, refunds, approvals).
- Replay with a low-privilege session and verify side effects.

### 6) DoS safety checks (low impact)

- Test for missing depth/complexity limits using small incremental increases.
- Stop early if latency/CPU impact is observed.

## Example queries

### Introspection (truncated)

```graphql
query IntrospectionQuery {
  __schema {
    types { name }
  }
}
```

### BOLA/IDOR-style test

Baseline (User A fetching own invoice id):

```graphql
query GetInvoice($id: ID!) {
  invoice(id: $id) {
    id
    total
    status
    tenantId
  }
}
```

Variables:

```json
{"id":"inv_user_a_123"}
```

Attack (User A fetching User B invoice id):

```json
{"id":"inv_user_b_456"}
```

If the attack returns B’s invoice details (or any tenant-bound data), the issue is proven.

### Field-level authorization test

```graphql
query GetUser($id: ID!) {
  user(id: $id) {
    id
    displayName
    email
    roles
  }
}
```

If `email`/`roles` are returned for users who should not see them, report a field-level authorization gap.

## Vulnerable signals

- Cross-tenant object reads or updates through resolver calls.
- Sensitive fields accessible to low-privilege roles.
- Mutations succeed without appropriate authorization.
- Unbounded query depth/aliasing causing large response payloads or latency spikes.

## Validation notes

- For auth issues, always include a follow-up proof (for example, show `tenantId` mismatch or an observable side effect).
- For DoS findings, keep tests minimal and stop once impact is observed; do not run “maximum” payloads on production.
- Note whether persisted queries or allowlists are in place; this changes the threat model.

## Control-level mitigations (no patch code)

- Enforce authorization in resolvers (object-level and field-level).
- Apply depth and complexity limits, plus rate limiting per user/IP.
- Disable introspection in production or gate it behind admin/trusted contexts.
- Prefer persisted queries / operation allowlists for sensitive deployments.
- Reduce error leakage; avoid exposing stack traces or internal identifiers.
