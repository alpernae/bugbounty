# A01 Broken Function-Level Authorization

## What it is

Function-level authorization failures happen when a protected action endpoint is reachable by a role that should not have that capability.

## What it is NOT (common false positives)

- A low-privilege user seeing the admin page HTML but the server blocks the actual action endpoints.
- A `200` response that contains an error payload and no state change (verify side effects).
- A state change that is permitted because the resource is actually owned by the caller (horizontal vs vertical confusion).

## Black-box probe strategy (Burp MCP)

1. Capture privileged requests from documentation, UI calls, or predictable endpoint naming.
2. Replay the request with a lower-privilege user session.
3. Modify role hints in headers or body only to test whether the server trusts client role claims.
4. Check whether state changes, exports, or admin actions complete.

Practical Burp tips:

- Prefer capturing a real privileged request first (admin UI action) so you have the exact method, path, and body shape.
- Keep two Repeater tabs: Baseline (admin) vs Attack (low-priv) to compare quickly.
- Always verify side effects via a follow-up read endpoint or UI refresh.

## Vulnerable signals

- Non-admin user receives `200` or `204` on admin-only actions.
- Server accepts role changes or privilege flags from client-controlled data.
- Unauthorized user can call bulk or destructive operations.

## Example evidence pattern

- Baseline: Admin disables a user and the user becomes disabled.
- Attack: Low-priv disables a user and the user becomes disabled.
- Proof: follow-up GET shows the disabled flag or admin audit logs reflect the change.

## Example attack request

```http
POST /api/admin/users/221/disable HTTP/1.1
Host: app.example.test
Authorization: Bearer <low-priv-token>
Content-Type: application/json

{"reason":"fraud-check"}
```

## Source code examples

```javascript
// Vulnerable: authentication exists, authorization check is missing
app.post('/api/admin/users/:id/disable', requireAuth, async (req, res) => {
  await userService.disable(req.params.id, req.body.reason);
  res.status(204).end();
});

// Controlled: explicit role and policy check before action
app.post('/api/admin/users/:id/disable', requireAuth, async (req, res) => {
  if (!req.user.roles.includes('admin')) {
    return res.status(403).json({ error: 'forbidden' });
  }
  await userService.disable(req.params.id, req.body.reason);
  res.status(204).end();
});
```

## Validation notes

- Verify action side effects in follow-up reads, audit logs, or UI state.
- Test multiple low-privilege roles to avoid role-mapping false positives.

## Control-level mitigations (no patch code)

- Enforce server-side authorization on every privileged action endpoint.
- Avoid trusting client-supplied role flags (headers/body claims) as authorization inputs.
- Apply consistent policy checks in controllers and in underlying service methods.
