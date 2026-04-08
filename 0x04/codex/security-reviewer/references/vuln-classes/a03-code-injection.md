# A03 Code Injection

## What it is
Code injection happens when untrusted input is treated as **code** (or a code-like expression) and executed by an interpreter/runtime.
In practice this often becomes **RCE** (read secrets, run OS commands, pivot to other services) and is usually higher impact than “logic bugs”.

## What it is NOT (common false positives)
- **Not SQL injection**: SQLi changes database queries via SQL sinks.
- **Not command injection**: command injection abuses OS command execution/shell parsing.
- **Not SSTI by default**: SSTI is a specific class where templates are compiled/rendered server-side.
- **Not dynamic dispatch** when inputs are mapped through strict allowlists (capabilities selected, not code executed).
- `ast.literal_eval(...)` is **not** arbitrary code execution like `eval(...)` (it is generally safer), though it can still be risky
	for untrusted parsing/DoS on very large inputs.

## Common variants
- **Expression injection**: user supplies an “expression” evaluated at runtime (`eval`, `exec`, `Function`, rule engines).
- **Dynamic module loading**: user controls module/function names used in `import`, `require`, reflection.
- **Script/plugin features**: “custom scripts”, “templates”, “rules”, “transformers” stored in DB and executed later (often blind/privileged).
- **Indirect code execution**: input reaches a templating engine, deserializer, or sandbox escape surface.

## Review checklist (sources → sinks)
Common sources:
- Admin “rules” or “filters”, workflow automation, data transformation DSLs
- User-provided “templates”, “snippets”, “calculations”, “routing expressions”
- Config values pulled from DB/remote sources and later executed

Common sinks (high risk):
- Python: `eval(...)`, `exec(...)`, `compile(...)` (treat any dynamic evaluation as a critical sink)
- JavaScript/TypeScript: `eval(...)`, `new Function(...)`, dynamic `require(...)` with user input
- JVM: dynamic scripting engines, reflection invoking arbitrary methods

Controls:
- Treat user input as **data**, not code (JSON configs, allowlisted operations).
- If you truly need a DSL, implement a **strict parser + allowlist evaluator** (no arbitrary functions/imports).
- Prefer isolation boundaries for untrusted execution (separate process, restricted runtime, no secrets, egress denied).

## Validation notes (safe)
- Prove user-controlled input reaches an execution sink (eval/exec/function compilation) without strong allowlisting.
- Determine execution identity/permissions and what secrets/resources are accessible at runtime.

## Examples

### Python expression injection

```python
# Vulnerable
@app.get('/api/calc')
@require_auth
def calc():
	expr = request.args['expr']
	return {'result': eval(expr)}  # code execution sink

# Controlled (treat input as data; allowlist operations)
ALLOWED_OPS = {
	'add': lambda a, b: a + b,
	'sub': lambda a, b: a - b,
}

@app.post('/api/calc')
@require_auth
def calc():
	op = request.json['op']
	a = int(request.json['a'])
	b = int(request.json['b'])
	fn = ALLOWED_OPS.get(op)
	if fn is None:
		abort(400, 'Unsupported operation')
	return {'result': fn(a, b)}
```

### Python dynamic import/reflection injection

```python
# Vulnerable
import importlib

@app.post('/api/run-plugin')
@require_auth
def run_plugin():
	module_name = request.json['module']
	mod = importlib.import_module(module_name)  # attacker influences what code gets loaded
	return {'result': mod.run()}

# Controlled (allowlist modules/actions)
ALLOWED_PLUGINS = {
	'safe_math': 'plugins.safe_math',
	'safe_text': 'plugins.safe_text',
}

@app.post('/api/run-plugin')
@require_auth
def run_plugin():
	plugin = request.json['plugin']
	module_name = ALLOWED_PLUGINS.get(plugin)
	if module_name is None:
		abort(400, 'Unsupported plugin')
	mod = importlib.import_module(module_name)
	return {'result': mod.run()}
```

### JavaScript code injection

```javascript
// Vulnerable
app.post('/api/run', requireAuth, (req, res) => {
	const userCode = req.body.code;
	const fn = new Function(userCode); // code execution sink
	const result = fn();
	res.json({ result });
});

// Controlled (allowlist actions; no dynamic code execution)
const ACTIONS = {
	ping: () => 'pong',
	version: () => process.version,
};

app.post('/api/run', requireAuth, (req, res) => {
	const action = req.body.action;
	if (!Object.prototype.hasOwnProperty.call(ACTIONS, action)) {
		return res.status(400).json({ error: 'Unsupported action' });
	}
	return res.json({ result: ACTIONS[action]() });
});
```
