# A03 SSTI

## What it is
SSTI (Server-Side Template Injection) occurs when untrusted input is treated as a template and rendered by the server.
Template engines often have access to helpers/objects that can lead to sensitive data disclosure or code execution.

## What it is NOT (common false positives)
- **Not variable substitution** into a fixed template (e.g., `render("hello {{name}}", {name})`).
- **Not client-side template issues** unless the server is compiling/evaluating attacker-controlled templates.
- **Not XSS**: XSS is about injecting script into HTML sent to browsers; SSTI is server-side template compilation.

## Common variants
- Direct rendering of user-provided template strings (`render_template_string(user_input)`).
- Stored templates (saved in DB) later rendered in emails/admin views (often “blind”).
- “Safe” flags/filters that disable auto-escaping or allow raw evaluation.

Additional common variants:
- “Theme” or “export format” customization where users provide template fragments.
- Translation/localization strings treated as templates.
- Templates executed in background jobs (email generation, PDF rendering) where impact is still severe.

## Review checklist
Look for:
- `render_template_string`, `Template(...).render(...)` on untrusted content
- User-controlled “templates”, “email bodies”, “theme strings”, “export formats”
- Template context containing powerful objects (request, config, filesystem, env)
- Any use of `eval`-like helpers inside template engines

Controls:
- Never render untrusted templates. Use fixed templates and pass untrusted data as variables.
- Minimize template context and disable dangerous features where supported.
- If templates are user-editable by design, isolate execution and enforce strict allowlists of operations.

## Validation notes (safe)
- Prove untrusted input reaches template compilation/rendering (not just variable substitution).
- Determine whether the template context exposes secrets/config or dangerous helpers.

## Examples

```python
# Vulnerable
from flask import render_template_string

@app.route('/custom_greeting')
def custom_greeting():
    template = request.args.get('template')
    return render_template_string(template)

# Controlled
from flask import render_template

@app.route('/custom_greeting')
def custom_greeting():
    name = request.args.get('name')
    return render_template('greeting.html', user_name=name)
```

```js
// Node.js example (illustrative)

// Vulnerable
const nunjucks = require('nunjucks');
app.get('/preview', (req, res) => {
    const tpl = req.query.template;
    res.send(nunjucks.renderString(tpl, { user: req.user }));
});

// Controlled
app.get('/preview', (req, res) => {
    res.render('preview.html', { name: req.query.name });
});
```
