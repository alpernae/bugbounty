# A01 CSRF on State Change

## What it is
CSRF occurs when a browser automatically attaches authentication (usually cookies) to a cross-site request
and the server performs a state change without verifying **request intent** (CSRF token or equivalent).

## What it is NOT (common false positives)
- **Not applicable to non-browser clients** by default (mobile/service-to-service) unless they also rely on ambient credentials.
- **Not primarily a CORS issue**: CORS controls browser reads; CSRF is about unintended state-changing writes.
- **Not prevented by `POST`**: method alone does not prevent CSRF.
- **Often not applicable when auth is purely `Authorization: Bearer ...`** (no auth cookies, no credentialed requests).
    (But if the bearer token is stored in cookies, CSRF can still apply.)
- **Not clickjacking** (UI redressing), though clickjacking can be used to *trigger* CSRF.

## Common variants
- JSON APIs that rely on cookie auth ("API" does not imply CSRF-safe).
- State changes via `GET` endpoints.
- Missing or misconfigured `SameSite` cookie attributes (defense-in-depth only).

Additional common variants:
- **GraphQL mutations** behind cookie auth with no CSRF protection.
- **Login CSRF** (forcing victim to log in as attacker-controlled account).
- **Account linking CSRF** (OAuth connect / webhook URL updates / email change).
- **Security-setting CSRF** (disable MFA, change recovery email, rotate API keys).
- **Token present-but-weak** (token not bound to session/user, token not rotated, token accepted from multiple sources).
- **CORS + credentials misconfig** (allowing cross-origin credentialed requests is dangerous, but still distinct from CSRF).

## Review checklist
Higher-risk conditions:
- Cookie-based auth (`session`, `jwt` in cookie) + state-changing endpoints
- Endpoints that accept `application/x-www-form-urlencoded` or `multipart/form-data`
- No per-request anti-CSRF token, no origin checks

Also check:
- Do state-changing endpoints accept `GET` (or side effects on `GET`)?
- Are cookies set with `SameSite=None` (or missing), enabling cross-site attachment more broadly?
- Are any endpoints intended for browser use missing a CSRF strategy (token or strict origin validation)?

Controls:
- CSRF tokens (synchronizer token pattern) or strict origin/referer validation.
- Set cookies with `SameSite=Lax/Strict`, `Secure`, `HttpOnly` (defense-in-depth).

Defense-in-depth add-ons:
- Require `Content-Type: application/json` for JSON APIs and reject form encodings when not needed.
- Use short session lifetimes and re-auth for high-risk changes.

## Validation notes (safe)
- Confirm the endpoint changes state using cookie auth without a CSRF token check.
- Identify whether CORS and cookie settings allow cross-site credentialed requests.

## Examples

### Classic form-post CSRF (browser cookies)

```html
<!-- Attacker-controlled page (illustrative) -->
<form action="https://target.example/api/update_email" method="POST">
    <input type="hidden" name="email" value="attacker@evil.test" />
    <input type="submit" value="Click" />
</form>
```

### Server-side token validation (synchronizer token)

```python
# Vulnerable
@app.route('/api/update_email', methods=['POST'])
@require_auth
def update_email():
    new_email = request.form['email']
    current_user.update_email(new_email)
    return 'Email updated'

# Controlled
from flask_wtf.csrf import validate_csrf
from wtforms import ValidationError

@app.route('/api/update_email', methods=['POST'])
@require_auth
def update_email():
    try:
        validate_csrf(request.form.get('csrf_token'))
    except ValidationError:
        abort(403, 'CSRF token validation failed')
    new_email = request.form['email']
    current_user.update_email(new_email)
    return 'Email updated'
```

### Origin check (simple mitigation for cookie-auth browser endpoints)

```python
from urllib.parse import urlparse

ALLOWED_ORIGINS = {'https://app.example.com'}

def require_same_origin_request() -> None:
    origin = request.headers.get('Origin')
    if origin and origin not in ALLOWED_ORIGINS:
        abort(403, 'Invalid Origin')

@app.route('/api/update_email', methods=['POST'])
@require_auth
def update_email():
    require_same_origin_request()
    # (Still consider CSRF tokens for defense-in-depth)
    new_email = request.form['email']
    current_user.update_email(new_email)
    return 'Email updated'
```
