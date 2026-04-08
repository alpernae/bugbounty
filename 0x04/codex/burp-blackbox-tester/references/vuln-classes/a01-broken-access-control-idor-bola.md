# A01 Broken Access Control (IDOR or BOLA)

## What it is

IDOR or BOLA happens when object identifiers are user-controlled and the server does not enforce ownership or tenant checks.

## What it is NOT (common false positives)

- Public or intentionally shareable resources (for example: public profiles, public invoices).
- “Different data shape” for the same object due to feature flags, locale, A/B tests, or partial responses.
- A cached response that is incorrectly shared (still a bug, but classify as caching/authorization caching rather than pure IDOR if the root cause is shared cache keys).
- “404 vs 403” differences without any evidence that cross-tenant data is accessible.

## Where it shows up

- Path identifiers: `/api/v1/invoices/{id}`, `/users/{id}/settings`, `/tenants/{tenantId}/...`.
- Nested resources: `/projects/{projectId}/members/{memberId}`.
- Bulk endpoints: `/api/v1/invoices?ids=1,2,3` or POST bodies with `[{"id":...}]`.
- “Action” endpoints that look non-resource-like: `/approve`, `/disable`, `/export`, `/download`.

## Black-box probe strategy (Burp MCP)

Precondition: ideally have two test accounts in different tenants (User A + User B), or at least two users with different ownership scopes.

1. Capture a legitimate object read or update request as User A.
2. Identify the object identifier(s): numeric id, uuid, slug, composite keys, “opaque” IDs in JSON.
3. Obtain a known-foreign identifier owned by User B:
    - create a resource as User B and capture its id, or
    - capture it from a list endpoint while logged in as User B.
4. Replay the request as User A with the identifier swapped.
5. Compare status, response body, and any observable side effects.
6. Repeat across methods (`GET`, `PUT`, `PATCH`, `DELETE`) and nested resources.

## Vulnerable signals

- `200` or `204` for foreign resources.
- Response data includes another user or tenant content.
- Update or delete succeeds for objects outside the tester account.

## Example evidence pattern

### Baseline (User A reading own invoice)

```http
GET /api/v1/invoices/88412 HTTP/1.1
Host: app.example.test
Authorization: Bearer <user-a-token>
Accept: application/json
```

### Attack (User A reading User B’s invoice)

```http
GET /api/v1/invoices/88413 HTTP/1.1
Host: app.example.test
Authorization: Bearer <user-a-token>
Accept: application/json
```

If the attack response includes a different tenant/account identifier (or invoice details known to belong to User B), the issue is proven.

## Example attack request

```http
GET /api/v1/invoices/88413 HTTP/1.1
Host: app.example.test
Authorization: Bearer <user-a-token>
Accept: application/json
```

## Source code examples

```python
# Vulnerable: object lookup is not bound to caller identity
@app.get("/api/v1/invoices/<int:invoice_id>")
def get_invoice(invoice_id):
    return db.fetch_one("SELECT * FROM invoices WHERE id = %s", (invoice_id,))

# Controlled: ownership is enforced in data access
@app.get("/api/v1/invoices/<int:invoice_id>")
def get_invoice(invoice_id):
    return db.fetch_one(
        "SELECT * FROM invoices WHERE id = %s AND tenant_id = %s",
        (invoice_id, current_user.tenant_id),
    )
```

## Validation notes

- Prove foreign ownership by matching tenant or account fields from known test accounts.
- Confirm exploitability is not caused by stale cache or shared demo data.

## Control-level mitigations (no patch code)

- Enforce object-level authorization on every object lookup and every state change.
- Prefer server-side tenant scoping in data access (filter by `tenant_id` / `owner_id`).
- For “download/export” endpoints, re-check authorization at generation time, not only at link creation time.
- Do not rely on unguessable IDs as the primary control (it can reduce opportunistic abuse but is not authorization).
