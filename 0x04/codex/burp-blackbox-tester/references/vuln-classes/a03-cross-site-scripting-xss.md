# A03 Cross-Site Scripting (XSS)

## What it is

XSS occurs when attacker-controlled input is returned to a browser without context-appropriate output encoding or sanitization.

## What it is NOT (common false positives)

- Reflected content that is HTML-escaped (for example `&lt;script&gt;`) and never executes.
- A payload that appears only in a JSON response that is not rendered in a browser context.
- DOM-based XSS where the server response is safe but client-side JS introduces the sink (still XSS, but evidence should include the client-side execution context).

## Black-box probe strategy (Burp MCP)

1. Locate reflection points in query parameters, form fields, headers, and stored content.
2. Test context-specific payloads for HTML, attribute, and script contexts.
3. Revisit pages where input is rendered later to check for stored XSS.
4. Confirm script execution in a controlled test browser context.

Practical Burp tips:

- Start by proving **unescaped reflection** in the raw HTML response before attempting execution.
- Record the exact context (HTML body vs attribute vs JS string) in your report.
- Prefer harmless payloads and a controlled test browser profile.

## Vulnerable signals

- Payload appears unescaped in HTML response.
- JavaScript executes when response is rendered.
- Stored payload executes for other users or privileged roles.

## Payload ideas (context-aware)

- HTML context: `<svg onload=alert(1)>`
- Attribute context: `" autofocus onfocus=alert(1) x="`
- JS string context (requires careful escaping): `';alert(1);//`

If CSP is present, also record whether CSP blocks execution (this may change severity).

## Example attack request

```http
GET /search?q=%3Cimg%20src%3Dx%20onerror%3Dalert(document.domain)%3E HTTP/1.1
Host: app.example.test
Cookie: session=<cookie>
```

## Source code examples

```javascript
// Vulnerable: direct rendering of untrusted data into HTML
app.get('/search', (req, res) => {
  res.send(`<h2>Results for: ${req.query.q}</h2>`);
});

// Controlled: output encoding or strict templating auto-escape
app.get('/search', (req, res) => {
  res.render('search', { query: req.query.q });
});
```

## Validation notes

- Separate reflected and stored XSS findings because risk and impact differ.
- Include the exact rendering context in the report (HTML body, attribute, JS string).

## Control-level mitigations (no patch code)

- Use context-appropriate output encoding (HTML/attr/JS/URL).
- Avoid building HTML via string concatenation; prefer templating with auto-escape.
- Consider a strict Content Security Policy as defense-in-depth.
