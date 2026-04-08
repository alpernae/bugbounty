# A01 Broken Access Control (IDOR / BOLA)

## What it is
IDOR (Insecure Direct Object Reference) / BOLA (Broken Object Level Authorization) occurs when **a user-controlled identifier**
(path param, query param, body field, GraphQL argument) reaches an object access/update operation
without being constrained by the **current principal** (user, tenant/org, role).

It can happen in **authenticated** or **unauthenticated** contexts — the defining property is missing *object-level* authorization.

## What it is NOT (common false positives)
- **Not SQL injection**: changing `id=1` to an “injection string” is a different class (injection into query structure).
- **Not a pure enumeration issue** unless it results in unauthorized read/write of a protected object.
- **Not mass assignment** (e.g., setting unexpected fields) unless it is used to switch ownership/tenant/object IDs.
- **Not an intended public resource** (e.g., a public profile) *if* the object truly contains only public data.
- **Not function-level authorization** (admin-only actions) unless the authorization failure is specifically at the *object* boundary.

## Common variants

### Unauthenticated IDOR
- The endpoint has no auth, and predictable IDs expose private objects.

### Authenticated horizontal IDOR (same privilege, different user)
- User A can read/modify User B’s resource by changing `invoice_id`, `user_id`, `document_id`, etc.

### Authenticated vertical escalation via IDOR (different privilege)
- A non-admin can act on **admin-owned or admin-only objects** by changing identifiers.

### Cross-tenant / org scoping failures
- Missing `tenant_id/org_id` predicate in data access (common with `.get(id)`/`.findByPk(id)` patterns).

### Nested resource mismatch
- Routes like `/orgs/{orgId}/users/{userId}` do not prove `userId ∈ orgId`.

### Batch/collection endpoints
- The API accepts `ids: [...]` and enforces authorization for some items but not all.

### Indirect object reference confusion
- Lookups by alternate keys (`email`, `slug`, `external_id`) return objects outside the requester’s scope.

### GraphQL object-level auth gaps
- Query/mutation arguments include `id`, and resolvers fetch by ID without checking owner/tenant.

### Download/export IDOR
- `file_id`, `export_id`, `report_id` can be swapped to download another user’s export.

## Review checklist (sources → sinks)

Sources (where identifiers enter):
- Path params: `/.../{id}`
- Query params: `?user_id=`, `?invoice_id=`, `?org=`
- JSON/body: `{ "resource_id": ..., "owner_id": ... }`
- Headers/cookies: `X-Org-Id`, `X-Account`
- GraphQL args: `invoice(id: ID!)`, `updateUser(userId: ID!)`

Sinks (where the object is fetched/used):
- ORM “by primary key” helpers: `.get(id)`, `.findByPk(id)`, `findUnique({ where: { id } })`
- Storage lookups: `download(file_id)`, `get_object(key)`
- Service-to-service calls: `billing.getInvoice(id)` without passing/validating tenant context

Controls:
- Prefer **scoped queries**: `WHERE id = :id AND owner_id = :user` (or `tenant_id = :tenant`).
- Centralize authorization (policy layer) and reuse it consistently across read + write paths.
- Avoid “fetch then compare” patterns that are easy to forget on secondary code paths.

## Validation notes (safe)
- Demonstrate unauthorized read/write by changing only the identifier.
- State the auth context clearly (unauthenticated vs authenticated; user vs admin; org A vs org B).
- Capture the trust boundary crossed (horizontal vs vertical vs cross-tenant).

## Examples

### Authenticated horizontal read IDOR (HTTP-level)

1. As User A, request your own invoice:

`GET /api/invoices/1001` → 200

2. Change the identifier:

`GET /api/invoices/1002` → 200 (but invoice belongs to User B)

### Write IDOR (higher impact)

`PATCH /api/shipping-addresses/55 {"line1":"..."}` → 200 (but address belongs to another user)

### Python (scoped query vs by-primary-key)

```python
# Vulnerable
@app.route('/api/invoices/<int:invoice_id>')
@require_auth
def get_invoice(invoice_id):
    invoice = Invoice.query.get(invoice_id)
    return jsonify(invoice.serialize())

# Controlled (scope in the query)
@app.route('/api/invoices/<int:invoice_id>')
@require_auth
def get_invoice(invoice_id):
    invoice = (
        Invoice.query
        .filter_by(id=invoice_id, owner_id=current_user.id)
        .first_or_404()
    )
    return jsonify(invoice.serialize())
```

### GraphQL resolver (object-level authorization)

```js
// Vulnerable
const invoice = (_parent, { id }, ctx) => ctx.db.invoice.findUnique({ where: { id } });

// Controlled (scope to principal)
const invoice = (_parent, { id }, ctx) =>
  ctx.db.invoice.findFirst({ where: { id, ownerId: ctx.user.id } });
```
