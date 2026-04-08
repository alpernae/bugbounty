# A03 Cross-Site Scripting (XSS)

## What it is
XSS happens when untrusted data is interpreted by the browser as executable content (HTML/JS/CSS/URL).
It commonly becomes an account/session compromise or an admin-panel compromise (stored/blind XSS).

## What it is NOT (common false positives)
- **Not server-side template injection (SSTI)**: SSTI is server-side template compilation; XSS is browser execution.
- **Not SQL injection**: SQLi targets database queries.
- **Not “any HTML in output”** if the content is properly encoded/escaped for the right context.
- **Not automatically fixed by sanitization**: sanitizers are allowlist-based and context-dependent; prefer encoding where possible.

## Common variants
- **Reflected XSS**: request data is reflected directly into the response.
- **Stored XSS**: attacker-controlled data is persisted and later rendered to other users.
- **DOM-based XSS**: client-side JS writes untrusted data into dangerous DOM sinks.
- **Self-XSS**: only affects the same user unless social engineering upgrades it.
- **Blind XSS**: data renders in a different, often privileged, view later (support/admin/log viewer).

## Review checklist (sources → sinks)
Common sources:
- Query params, form fields, JSON bodies
- HTTP headers (User-Agent, Referer), uploaded filenames, markdown/rich-text
- DB fields and log entries (often lead to blind XSS)

Common sinks:
- Server-rendered string concatenation into HTML (`f"<div>{user}</div>"`)
- Template engines with auto-escape disabled, “safe HTML” flags, `render_template_string`
- Frontend: `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write`, React `dangerouslySetInnerHTML`

Controls (pick the simplest that fits):
- Prefer template engines with **auto-escaping enabled**; avoid manual HTML string building.
- Use **context-aware output encoding** (HTML text vs attribute vs URL vs JS context).
- If you must allow user HTML: sanitize with a proven allowlist sanitizer (defense-in-depth: CSP).

Additional notes:
- Escaping for **HTML text** is not the same as validating **URLs** (e.g., preventing `javascript:` or external redirects).
- CSP can reduce impact, but is not a substitute for correct encoding/sanitization.

## Validation notes (safe)
- Prove a concrete path from a user-controlled source to a specific sink and rendering context.
- For stored/blind cases, identify the secondary view where the data is rendered (admin UI, email, PDF, log viewer).

## Examples

### Reflected XSS (server-side HTML response)

```python
# Vulnerable
@app.route('/welcome')
def welcome():
    name = request.args.get('name', 'Guest')
    return f'<h1>Welcome back, {name}!</h1>'

# Controlled (encode output; template auto-escape also works)
from markupsafe import escape

@app.route('/welcome')
def welcome():
    name = request.args.get('name', 'Guest')
    return f'<h1>Welcome back, {escape(name)}!</h1>'
```

### Stored XSS (persisted content rendered later)

```python
# Vulnerable
from flask import abort, request

@app.post('/api/comments')
@require_auth
def create_comment():
    body = request.form['body']
    Comment.create(author_id=current_user.id, body=body)
    return {'ok': True}

@app.get('/admin/comments')
@require_auth
def admin_comments():
    if not current_user.is_admin:
        abort(403)
    comments = Comment.query.order_by(Comment.id.desc()).limit(50).all()
    items = ''.join(f'<li>{c.body}</li>' for c in comments)  # stored XSS sink
    return f'<ul>{items}</ul>'

# Controlled (render via template engine with auto-escape enabled)
from flask import render_template

@app.get('/admin/comments')
@require_auth
def admin_comments():
    if not current_user.is_admin:
        abort(403)
    comments = Comment.query.order_by(Comment.id.desc()).limit(50).all()
    return render_template('admin/comments.html', comments=comments)
```

### DOM-based XSS (frontend)

```javascript
// Vulnerable
const name = new URLSearchParams(location.search).get('name');
document.getElementById('greet').innerHTML = `Hello ${name}`;

// Controlled
const safeName = new URLSearchParams(location.search).get('name') ?? '';
document.getElementById('greet').textContent = `Hello ${safeName}`;
```

### Self-XSS (user-only preview)

```javascript
// Vulnerable (often “only me” preview, but can be social-engineered)
function updatePreview(value) {
  document.getElementById('preview').innerHTML = value;
}

// Controlled
function updatePreview(value) {
  document.getElementById('preview').textContent = value;
}
```

### URL/attribute context XSS (validate redirect/URL targets)

```python
# Vulnerable
@app.get('/continue')
def continue_to():
    next_url = request.args.get('next')
    return f'<a href="{next_url}">Continue</a>'

# Controlled (restrict to relative paths)
from urllib.parse import urlparse
from markupsafe import escape

@app.get('/continue')
def continue_to():
    next_url = request.args.get('next', '/')
    parsed = urlparse(next_url)
    if parsed.scheme or parsed.netloc:
        abort(400, 'Invalid next')
    return f'<a href="{escape(next_url)}">Continue</a>'
```

### Blind XSS (header/log content rendered later in privileged UI)

```python
# Vulnerable (attacker controls User-Agent; admin later views it)
from flask import abort

@app.get('/admin/audit-log')
@require_auth
def audit_log():
    if not current_user.is_admin:
        abort(403)
    entries = AuditLog.query.order_by(AuditLog.id.desc()).limit(100).all()
    rows = ''.join(
        f'<tr><td>{e.user_agent}</td><td>{e.path}</td></tr>'
        for e in entries
    )
    return f'<table>{rows}</table>'

# Controlled (encode fields when rendering)
from markupsafe import escape

@app.get('/admin/audit-log')
@require_auth
def audit_log():
    if not current_user.is_admin:
        abort(403)
    entries = AuditLog.query.order_by(AuditLog.id.desc()).limit(100).all()
    rows = ''.join(
        f'<tr><td>{escape(e.user_agent)}</td><td>{escape(e.path)}</td></tr>'
        for e in entries
    )
    return f'<table>{rows}</table>'
```
