# A03 SQL Injection

## What it is
SQL injection happens when untrusted input is incorporated into SQL in a way that lets an attacker
change the **structure** of the query (not just the value), such as altering `WHERE` logic, adding joins/unions,
or controlling identifiers.

Impact ranges from data exfiltration and auth bypass to, in some stacks, filesystem access or OS command execution
via database features.

## What it is NOT (common false positives)
- **Not IDOR/BOLA**: changing `?id=1` to `?id=2` to access another user's row is object authorization, not injection.
- **Not NoSQL injection** (Mongo operator injection, etc.) — similar concept, different sinks.
- **Not safe parameter binding** where user input is passed as a bound value/placeholder.
- **Not “dynamic query building”** per se if it uses query builders and safe bindings end-to-end.

## Common variants

### String concatenation / interpolation
- f-strings / template literals / `sprintf` used to build SQL.

### ORM escape hatches
- `raw()`, `text()`, `execute()`, `where("..." + user)` in ORMs.

### Dynamic identifiers
- `ORDER BY {col}`, `SELECT {columns}`, dynamic table names, dynamic `LIMIT/OFFSET` without allowlisting.

### Blind SQLi
- The response does not include query output or errors; impact is inferred via timing/boolean behavior.

### Second-order / stored SQLi
- Attacker-controlled input is stored first (DB, cache, logs) and later used in a raw query.

### Auth bypass injection
- Login / session / password reset flows build SQL from user input.

## Review checklist

Look for:
- Raw SQL construction via string formatting (across all languages)
- ORM escape hatches that accept raw SQL strings
- Use of user input in identifier positions (columns, tables, `ORDER BY`)
- “Stored then later used” flows: admin search, exports, reporting jobs

Controls:
- Always use parameterized queries for **values**.
- For dynamic identifiers, use strict allowlists (map `sort=created` → `ORDER BY created_at`).
- Prefer query builders/ORM methods that bind values by default.

## Validation notes (safe)
- Prove attacker input can modify query semantics (not just provide a value).
- For blind cases, identify measurable behavior changes (timing, row-count deltas, branch decisions).
- For second-order cases, show the storage point and the later execution point.

## Examples

### Python (string interpolation vs binding)

```python
# Vulnerable
query = f"SELECT * FROM users WHERE id = {user_id}"
cursor.execute(query)

# Controlled
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_id,))
```

### Node.js (template literal vs placeholders)

```js
// Vulnerable
const result = await pool.query(`SELECT * FROM orders WHERE status = '${status}'`);

// Controlled
const result = await pool.query('SELECT * FROM orders WHERE status = $1', [status]);
```

### Dynamic `ORDER BY` (allowlist)

```python
# Vulnerable
query = f"SELECT * FROM products ORDER BY {sort_col}"

# Controlled
ALLOWED_SORT = {
	'created': 'created_at',
	'price': 'price',
	'name': 'name',
}
col = ALLOWED_SORT.get(sort_col)
if col is None:
	raise ValueError('Invalid sort')
query = f"SELECT * FROM products ORDER BY {col}"
```

### Second-order SQLi (stored then executed)

```python
# Vulnerable pattern
# 1) store user-controlled search filter
SavedSearch.create(user_id=current_user.id, raw_where=request.json['where'])

# 2) later, use it in a raw query
saved = SavedSearch.query.get(saved_search_id)
cursor.execute(f"SELECT * FROM invoices WHERE {saved.raw_where}")

# Controlled approach
# Store structured filters, not raw SQL fragments, then compile with allowlists.
```
