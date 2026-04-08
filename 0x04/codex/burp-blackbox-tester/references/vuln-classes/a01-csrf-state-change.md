# A01 CSRF on State Change

## What it is

CSRF exists when a browser-authenticated endpoint changes state without verifying anti-CSRF controls.

## What it is NOT (common false positives)

- Endpoints that require an `Authorization: Bearer ...` token that is not automatically attached by a browser.
- Idempotent `GET` requests that do not change state (though “GET that changes state” is itself a bug).
- State change attempts blocked by server-side validation unrelated to CSRF (verify with a legitimate request first).

## Where it shows up

- Cookie-authenticated web apps with form POSTs.
- JSON APIs called by browser sessions (single-page apps) when cookies are used.
- “Account settings” or “payment method” endpoints where browser auto-sends cookies.

## Black-box probe strategy (Burp MCP)

1. Identify state-changing endpoints that rely on cookie sessions.
2. Capture a legitimate state change request (baseline) and confirm it succeeds.
3. Remove CSRF defenses and resend:
   - drop CSRF token header (for example `X-CSRF-Token`) and/or token field,
   - remove “double-submit” cookie if present.
4. Modify `Origin` / `Referer` to a cross-site value and resend.
5. If applicable, generate a minimal HTML form PoC and validate the state change.

Practical Burp tips:

- Many frameworks include a “Generate CSRF PoC” helper for captured requests; use it to validate browser realism.
- If tokens are rotated, capture the token extraction logic (where it appears in HTML/JS) so the report can explain the intended control.

## Vulnerable signals

- State change succeeds without a valid CSRF token.
- Server does not enforce `Origin` or `Referer` checks.
- `SameSite=None` cookies combined with missing CSRF defenses.

## Example evidence pattern

- Baseline: `POST /account/email` succeeds with a CSRF token.
- Attack: the same request succeeds after removing CSRF token + setting `Origin: https://evil.example`.
- Proof: `GET /account` shows email changed.

## Example PoC

```html
<form action="https://app.example.test/account/email" method="POST">
  <input type="hidden" name="email" value="attacker@example.test" />
</form>
<script>document.forms[0].submit();</script>
```

## Source code examples

```python
# Vulnerable: session cookie is required, but no CSRF validation is performed
@app.post('/account/email')
def change_email():
    new_email = request.form['email']
    db.execute('UPDATE users SET email = %s WHERE id = %s', (new_email, session['uid']))
    return {'ok': True}

# Controlled: state changes require CSRF token validation bound to session
@app.post('/account/email')
def change_email():
    token = request.form.get('csrf_token', '')
    validate_csrf_or_403(token, session['uid'])
    new_email = request.form['email']
    db.execute('UPDATE users SET email = %s WHERE id = %s', (new_email, session['uid']))
    return {'ok': True}
```

## Validation notes

- Confirm request is browser-realistic (cookies, content type, method).
- Do not classify as CSRF when endpoint uses bearer token auth outside browser context.

## Control-level mitigations (no patch code)

- Use per-request CSRF tokens bound to the session and verify them on state change.
- Enforce `Origin`/`Referer` checks as a defense-in-depth layer.
- Prefer `SameSite=Lax` or `SameSite=Strict` cookies where compatible; do not rely on SameSite alone.
