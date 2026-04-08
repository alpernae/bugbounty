# LLM02 Insecure Output Handling

## What it is

Insecure output handling occurs when an application treats model output as trusted and feeds it into execution sinks
(code execution, SQL execution, command execution, template rendering, file writes, network calls) without strong validation.

This is often a composition vulnerability: prompt injection or normal model behavior produces output that becomes dangerous
only because the application executes it.

## What it is NOT (common false positives)

- Showing model output to a user (that is usually an output-encoding/UI concern).
- Using model output only as untrusted text (summaries/classification) with no execution path.
- “The model said something wrong” without a path to a sink.

## Black-box probe strategy (Burp MCP)

1. Identify where model output is consumed by the system:
   - “agent” features that run actions,
   - workflows that generate SQL/filters,
   - automation that writes files/configs,
   - features that fetch URLs or call APIs based on model output.
2. Use safe, canary-style probes to detect execution:
   - ask the model to output a structured value that would trigger a harmless network fetch,
   - observe whether the backend actually performs that fetch (Burp Collaborator).
3. Validate that the execution is driven by model output (not by direct user-provided parameters).
4. Confirm missing validation/allowlists:
   - can the model output arbitrary destinations/commands/queries,
   - or is it constrained by a strict schema and allowlisted operations.

Practical Burp tips:

- Correlate collaborator interactions with a unique ID in the model output.
- Keep tests low impact and reversible.

## Vulnerable signals

- The system performs actions directly derived from model output without confirmation.
- The backend makes network requests to attacker-influenced URLs purely because the model output says so.
- The system accepts arbitrary “tool names” or arguments produced by the model.

## Example evidence pattern

- Baseline: model output is displayed only.
- Attack: model output causes a backend side effect (for example, an outbound request to a collaborator URL).

## Source code examples

```python
# Vulnerable: executing model output
llm_response = llm.complete('Generate python code to parse the data.')
exec(llm_response)

# Controlled: schema + allowlist
import json

llm_response = llm.complete(
    'Return parsing steps as JSON with keys: {"format": "csv|json", "columns": [..]}. No extra keys.'
)
config = json.loads(llm_response)

if config.get('format') not in {'csv', 'json'}:
    raise ValueError('Invalid format')

apply_safe_config(config)
```

## Validation notes

- Prove a model response can reach an execution sink without strong validation.
- Avoid testing with dangerous commands. Prefer collaborator-based canaries and strict scoping.

## Control-level mitigations (no patch code)

- Constrain model output to a strict schema and validate it.
- Use allowlists and “data-only” configs; never treat output as executable.
- Separate suggest → approve → execute for high-impact actions.
- Run unavoidable execution in sandboxes with no secrets and restricted egress.
