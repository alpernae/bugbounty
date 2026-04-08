# A01 Broken Function-Level Authorization

## What it is
Function-level authorization fails when a caller can invoke a **privileged capability** (admin action, sensitive workflow step,
internal operation) because the handler lacks a **server-side permission check**.

The defining property is not “which object,” but “which *capability*” (e.g., delete user, export data, issue refunds, rotate keys).

## What it is NOT (common false positives)
- **Not IDOR/BOLA**: object-level authorization failures are about *which record* you can access/modify.
- **Not CSRF**: CSRF is about cross-site request intent; broken function-level auth is about missing privilege checks.
- **Not “security through obscurity”**: relying on hidden UI routes or unlinked endpoints is not authorization.
- **Not a safe feature flag** unless the flag is enforced **server-side** at the action boundary.
- **Not input validation**: validating parameters does not replace RBAC/ABAC checks.

## Common variants

### Unauthenticated function access
- Privileged endpoint missing authentication entirely.

### Authenticated but missing privilege check
- Endpoint requires a session, but does not enforce `admin`, `manager`, `support`, `finance`, etc.

### Method/route split gaps
- `GET /admin/users` is protected, but `POST /admin/users/delete` is not.

### “Client-side only” admin gating
- UI hides admin buttons, but direct HTTP calls succeed.

### Confused deputy / internal-only assumptions
- Service-to-service routes accept external traffic, or internal credentials are reachable and used to perform privileged operations.

### Vertical privilege escalation actions
- Changing roles/permissions, impersonation, password reset flows, token issuance, exports.

## Review checklist

Hot-spot route naming:
- `/admin`, `/internal`, `/manage`, `/debug`, `/ops`, `/maintenance`, `/support`, `/backoffice`

High-impact actions:
- Role/permission changes, user deletion, refunds/payouts, exports, API key/token issuance, feature-flag flips,
    account takeover primitives (reset MFA/email/password), impersonation.

Anti-patterns:
- Authorization based on request parameters (e.g., `is_admin=true`)
- Authorization based only on UI gating
- Missing checks in background jobs/queues that are triggered by low-privilege users

Controls:
- Enforce RBAC/ABAC at the handler boundary (middleware/decorators/policy checks).
- Use a consistent authorization helper (one place to reason about access).
- Log privileged actions with actor identity, target, and request metadata.

## Validation notes (safe)
- Prove a low-privilege user (or unauthenticated caller) can reach the privileged code path.
- Record the capability boundary crossed (user → admin, support-only → public).

## Examples

### Python (missing admin check)

```python
# Vulnerable
@app.route('/api/admin/delete_user/<int:user_id>', methods=['POST'])
@require_auth
def delete_user(user_id):
        User.query.get(user_id).delete()
        return 'User deleted'

# Controlled
@app.route('/api/admin/delete_user/<int:user_id>', methods=['POST'])
@require_auth
def delete_user(user_id):
        if not current_user.is_admin:
                abort(403, 'Admin privileges required')
        User.query.get(user_id).delete()
        return 'User deleted'
```

### Node/Express (missing middleware)

```js
// Vulnerable
app.post('/api/admin/refund', requireAuth, async (req, res) => {
    await refundService.refundOrder(req.body.orderId);
    res.json({ ok: true });
});

// Controlled
app.post('/api/admin/refund', requireAuth, requireRole('admin'), async (req, res) => {
    await refundService.refundOrder(req.body.orderId);
    res.json({ ok: true });
});
```

### GraphQL mutation (privileged capability)

```js
// Vulnerable
const makeUserAdmin = (_p, { userId }, ctx) => ctx.db.user.update({ where: { id: userId }, data: { role: 'admin' } });

// Controlled
const makeUserAdmin = async (_p, { userId }, ctx) => {
    if (!ctx.user?.isAdmin) throw new Error('Forbidden');
    return ctx.db.user.update({ where: { id: userId }, data: { role: 'admin' } });
};
```
