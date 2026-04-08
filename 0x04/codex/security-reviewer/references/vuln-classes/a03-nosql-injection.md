# A03 NoSQL Injection

## What it is
NoSQL injection occurs when attacker-controlled input changes the structure of a NoSQL query or update operation.
Instead of being treated as a data value, input is interpreted as part of the query language (operators, expressions,
filters, pipelines), enabling auth bypass, data exposure, or unauthorized modifications.

While many examples involve MongoDB-style operators (e.g., keys starting with `$`), the general pattern applies to any
query language where you combine untrusted input into a query structure.

## What it is NOT (common false positives)
- **Not IDOR/BOLA**: accessing another record by changing an ID is access control, not injection.
- **Not safe parameterization** in query builders that bind values and do not accept raw operator objects.
- **Not “NoSQL is safe from injection”**: injection exists, it just looks different than SQLi.
- **Not purely a validation bug** unless validation failure allows query structure control.

## Common variants

### Operator injection (type confusion)
- API expects a string (e.g., `email`), but JSON parsing allows an object.
- The attacker supplies a structured object that the driver treats as query operators.

### Filter object pass-through
- The application accepts a “filter” object from users and passes it directly to `find(...)` or `aggregate(...)`.

### Update operator injection / mass update
- User-controlled input is used as an update document, allowing operators like `$set`, `$inc`, `$push`.

### Aggregation pipeline injection
- User controls stages in an aggregation pipeline (or parts of a stage), changing semantics or accessing unintended data.

### Regex/query-language injection
- User controls regex patterns or query DSL fragments, enabling bypasses or expensive execution (ReDoS adjacency).

## Review checklist (sources → sinks)

Common sources:
- `req.body.filter`, `req.query.filter`, `search`, `where`, `criteria`, `query`
- Sorting/pagination fields (`sort`, `orderBy`, `fields`, projections)
- “Advanced search” features in admin/support tools

Common sinks:
- Mongo/Mongoose: `Model.find(filter)`, `findOne(filter)`, `aggregate(pipeline)`, `updateOne(filter, update)`
- PyMongo: `collection.find(filter)`, `find_one(filter)`, `update_one(filter, update)`
- Search backends: Elasticsearch query bodies constructed from user input

Red flags:
- Passing request JSON directly as a query/update document
- Accepting arbitrary keys that start with `$` or contain `.`
- Storing user-defined filters and executing them later (second-order)

## Controls
- Validate and type-check inputs: ensure expected strings/numbers are not objects.
- Deny or strip operator-like keys (commonly keys starting with `$` and keys containing `.`) unless explicitly needed.
- Prefer allowlists for filter fields (`status`, `createdAt`, `ownerId`) and map user inputs to known-safe query shapes.
- Avoid “raw filter” APIs; if advanced filtering is required, implement a strict, data-only filter language.
- Enforce authorization in the query itself (tenant/user scoping), even for admin tools.

## Validation notes (safe)
- Prove attacker input can influence the *query structure* (operators/fields/stages), not just the value.
- Identify the boundary crossed (auth bypass, cross-tenant read, unauthorized update).
- For second-order cases, show the storage point and the later query execution point.

## Examples

### Node.js / Mongoose: filter pass-through

```js
// Vulnerable: user-controlled filter object is passed through
app.post('/api/users/search', requireAuth, async (req, res) => {
  const users = await User.find(req.body.filter).limit(50);
  res.json({ users });
});

// Controlled: allowlist fields and enforce types
const ALLOWED_FIELDS = new Set(['email', 'status']);

function pickAllowedFilter(input) {
  const out = {};
  for (const [key, value] of Object.entries(input ?? {})) {
    if (!ALLOWED_FIELDS.has(key)) continue;
    if (typeof value !== 'string') continue;
    out[key] = value;
  }
  return out;
}

app.post('/api/users/search', requireAuth, async (req, res) => {
  const filter = pickAllowedFilter(req.body.filter);
  const users = await User.find({ tenantId: req.user.tenantId, ...filter }).limit(50);
  res.json({ users });
});
```

### Node.js: login query with type enforcement

```js
// Vulnerable if email/password can be objects (JSON parsing) rather than strings
const user = await User.findOne({ email: req.body.email, password: req.body.password });

// Controlled: validate types first
if (typeof req.body.email !== 'string' || typeof req.body.password !== 'string') {
  return res.status(400).json({ error: 'Invalid input' });
}
const user = await User.findOne({ email: req.body.email, password: req.body.password });
```

### Python / PyMongo: update operator injection

```python
# Vulnerable: user-controlled update document
collection.update_one({'_id': doc_id}, request.json['update'])

# Controlled: allowlist update fields and build the update server-side
allowed_fields = {'display_name', 'timezone'}
requested = request.json.get('update', {})
set_fields = {k: v for k, v in requested.items() if k in allowed_fields and isinstance(v, str)}
collection.update_one({'_id': doc_id, 'tenant_id': current_user.tenant_id}, {'$set': set_fields})
```
