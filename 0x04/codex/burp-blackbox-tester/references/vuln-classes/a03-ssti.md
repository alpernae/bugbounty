# A03 SSTI

## What it is

SSTI (Server-Side Template Injection) occurs when untrusted input is treated as a template and rendered by the server.
Template engines often expose helpers/objects that can lead to sensitive data disclosure or code execution.

## What it is NOT (common false positives)

- Not variable substitution into a fixed template (untrusted data placed into a trusted template).
- Not client-side template issues unless the server is compiling/evaluating attacker-controlled templates.
- Not XSS: XSS is client-side script injection; SSTI is server-side template compilation.

## Black-box probe strategy (Burp MCP)

1. Identify template-like features:
   - preview endpoints,
   - email templates,
   - report/export generation,
   - “custom messages”, “themes”, “snippets”, “notifications”.
2. Capture a baseline request where your input is rendered.
3. Try harmless template expressions and compare output to baseline.
   - Common probe: `{{7*7}}` (many template engines)
   - Alternative probes (engine-dependent): `${7*7}`, `#{7*7}`, `<%= 7*7 %>`
4. Look for:
   - evaluated output (for example `49`),
   - template engine error messages,
   - stored/blind execution (save template, then trigger a render later).

Practical Burp tips:

- Confirm server-side execution by inspecting the raw HTTP response.
- If the render happens asynchronously (email/PDF), collect evidence via the generated artifact.

## Vulnerable signals

- Expression evaluation output appears in the rendered content.
- Error messages reference a template engine (for example Jinja2, Nunjucks, Freemarker, Thymeleaf).
- Changing the expression changes the output in a payload-dependent way.

## Example attack request

```http
POST /api/v1/preview HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Content-Type: application/json

{"template":"Hello {{7*7}}"}
```

## Example evidence pattern

- Baseline output: `Hello {{7*7}}`
- Injected output: `Hello 49`

If the server returns `49`, it is compiling/evaluating attacker-controlled templates.

## Source code examples

```python
# Vulnerable
from flask import render_template_string

@app.get('/custom_greeting')
def custom_greeting():
    template = request.args.get('template')
    return render_template_string(template)

# Controlled
from flask import render_template

@app.get('/custom_greeting')
def custom_greeting():
    name = request.args.get('name')
    return render_template('greeting.html', user_name=name)
```

## Validation notes

- Prove the input reaches template compilation/rendering (not just string replacement).
- Avoid “weaponized” payloads. A benign math expression is usually enough to prove SSTI.
- For stored templates, verify execution under the intended privilege context (user vs admin render views).

## Control-level mitigations (no patch code)

- Never render untrusted templates. Use fixed templates and pass untrusted data as variables.
- Minimize template context and disable dangerous features where supported.
- If user-editable templates are required by design, isolate execution and enforce strict allowlists.
