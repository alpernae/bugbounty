# GraphQL Security Pitfalls

## What it is
GraphQL consolidates many capabilities into a single endpoint with a typed schema and resolver functions.
Most GraphQL security issues are not “GraphQL exploits” but **authorization, validation, and resource-control** failures
in resolvers, schema design, and query execution.

## What it is NOT (common false positives)
- **GraphQL is not inherently insecure**: a well-designed schema with strong authz and limits can be safe.
- **Not SQL injection**: GraphQL is a query language for your API; injection risks depend on downstream sinks.
- **Not solved by hiding GraphiQL/Playground**: removing UI tools does not enforce authorization.
- **Not “the gateway auth is enough”** if individual resolvers do not enforce object/field-level policy.

## Common variants

### Broken object-level authorization in resolvers (BOLA/IDOR)
- Resolvers fetch records by ID without tenant/user scoping.
- Global IDs encourage “try other IDs” patterns if not scoped.

### Broken function-level authorization (BFLA)
- Privileged mutations (refund, role changes, exports) lack role/permission checks.

### Field-level authorization gaps
- The object is authorized, but specific fields are not (e.g., `email`, `mfaSecrets`, `billingDetails`).

### Query complexity and depth DoS
- Deeply nested selections or expensive fields cause heavy DB work and N+1 patterns.

### Batching/alias abuse
- One request performs many operations (aliases or batching), bypassing naive per-request rate limits.

### Introspection and schema leakage
- Introspection reveals types/fields that help attackers map privileged capabilities.

### Error leakage
- Stack traces, internal exception messages, and resolver details leak implementation and sensitive data.

### SSRF adjacency in resolvers
- Resolvers that fetch URLs (preview, import, webhook test) can become SSRF vectors if destination validation is weak.

## Review checklist

Endpoint and transport:
- Are queries/mutations/subscriptions authenticated?
- Are batched requests enabled? Are they bounded?
- Are errors sanitized (no stack traces, no internal URLs/secrets)?

Authorization:
- Do resolvers enforce tenant scoping in queries?
- Are privileged mutations protected with explicit permission checks?
- Is there field-level auth for sensitive fields?

Resource controls:
- Is there a maximum depth/complexity/cost limit?
- Are pagination limits enforced (no unbounded `first: 100000`)?
- Are expensive resolvers protected (timeouts, caching, dataloaders)?

Exposure:
- Is introspection enabled in production for untrusted clients?
- Are debug tools and schema docs restricted?

## Controls
- Centralize authorization (middleware/directives) and still enforce per-resolver scoping.
- Implement field-level policies for sensitive fields.
- Add depth/complexity/cost limits and strict pagination bounds.
- Disable introspection for untrusted clients in production (or require admin/authz).
- Limit or disable batching; apply per-operation rate limits.
- Normalize and sanitize error responses.
- For URL-fetching resolvers, apply SSRF defenses (allowlists, DNS/IP checks, redirect handling).

## Validation notes (safe)
- Prove a low-privilege user can query or mutate something across a boundary (cross-tenant/user, admin-only capability).
- For DoS risks, show a query shape that produces disproportionate work (depth, breadth, N+1) and the missing limits.
- For introspection leakage, show it is reachable by untrusted clients and reveals privileged fields/mutations.

## Examples

### Resolver scoping (cross-tenant read)

```js
// Vulnerable
const user = async (_p, { id }, ctx) => {
  return ctx.db.user.findUnique({ where: { id } });
};

// Controlled: scope by tenant and/or ownership
const user = async (_p, { id }, ctx) => {
  return ctx.db.user.findFirst({ where: { id, tenantId: ctx.user.tenantId } });
};
```

### Privileged mutation (role change)

```js
// Vulnerable
const makeUserAdmin = async (_p, { userId }, ctx) => {
  return ctx.db.user.update({ where: { id: userId }, data: { role: 'admin' } });
};

// Controlled
const makeUserAdmin = async (_p, { userId }, ctx) => {
  if (!ctx.user?.isAdmin) throw new Error('Forbidden');
  return ctx.db.user.update({ where: { id: userId }, data: { role: 'admin' } });
};
```

### Complexity limiting (illustrative)

```js
// Pseudocode: enforce depth/complexity limits for untrusted clients
// - set max depth
// - set max complexity/cost
// - enforce timeouts
function validateGraphQLQuery({ query, variables, user }) {
  if (!user) throw new Error('Unauthorized');
  enforceMaxDepth(query, 10);
  enforceMaxCost(query, 200);
}
```
