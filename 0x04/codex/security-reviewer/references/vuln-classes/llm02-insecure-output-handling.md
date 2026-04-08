# LLM02 Insecure Output Handling

## What it is
Insecure output handling occurs when an application treats model output as **trusted** and feeds it into execution sinks
(code execution, SQL execution, command execution, template rendering, file writes, network calls) without strong validation.

This is often a *composition* vulnerability: prompt injection or normal model behavior produces output that becomes dangerous
only because the application executes it.

## What it is NOT (common false positives)
- Showing model output to a user (that’s usually a UI/output-encoding problem, not “output handling”).
- Using the model for low-impact tasks where output is never executed (summaries, classification) and is treated as untrusted text.
- “Model said something wrong” without a path to a sink.

## Common variants
- Executing generated code (`exec`, `eval`, `new Function`).
- Running model-suggested shell commands or infrastructure actions.
- Using model output to build DB queries or migrations.
- Using model output as an authorization decision (“allow/deny”) without independent verification.
- Treating model output as a trusted config (IAM policies, firewall rules, CI/CD steps).

## Review checklist
Look for sinks like:
- `exec(...)`, `eval(...)`, dynamic imports, templating
- Database execution of model-generated SQL
- Shell/command execution or deployment actions derived from model output
- File writes (paths, filenames) derived from model output
- Network calls (URLs, hosts) derived from model output (SSRF adjacency)

## Controls
- Constrain model output to a strict schema (JSON) and validate it.
- Use allowlists and “data-only” configs; never treat output as executable.
- Prefer a “suggest → human approve → execute” separation for high-impact actions.
- Run unavoidable execution in sandboxes with no secrets and strict egress restrictions.

## Validation notes (safe)
- Prove a model response can reach an execution sink without strong validation.
- Identify what attacker-controlled input influences the model output (prompt injection, RAG, user input).

## Examples

### Vulnerable: executing model output

```python
llm_response = llm.complete('Generate python code to parse the data.')
exec(llm_response)
```

### Controlled: schema + allowlist

```python
import json

llm_response = llm.complete(
	'Return parsing steps as JSON with keys: {"format": "csv|json", "columns": [..]}. No extra keys.'
)
config = json.loads(llm_response)

if config.get('format') not in {'csv', 'json'}:
	raise ValueError('Invalid format')

apply_safe_config(config)
```
