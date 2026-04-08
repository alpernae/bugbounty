# LLM08 Excessive Agency

## What it is

Excessive agency occurs when an LLM/agent can take high-impact actions (execute commands, mutate data, spend money,
deploy changes, access sensitive systems) without strong guardrails, approvals, or least-privilege tool access.

This is a capability boundary issue: what the model can do, not what it says.

## What it is NOT (common false positives)

- An assistant that only provides suggestions (no tool execution) is usually not “agentic”.
- Normal automation with strict allowlists, approvals, and auditing is not excessive agency.
- Read-only tools are lower risk (but can still disclose sensitive data).

## Black-box probe strategy (Burp MCP)

1. Identify whether the feature is truly agentic:
   - does it call tools/APIs, write data, or perform actions on behalf of the user?
2. Enumerate action surfaces from UI/API behavior:
   - “create”, “delete”, “send”, “deploy”, “run”, “execute”, “approve”.
3. Test for missing approval gates using safe actions:
   - attempt a high-impact command via natural language,
   - confirm whether the system requires explicit confirmation/step-up auth.
4. Test for prompt-injection-driven actions:
   - embed “do action X” in untrusted content and see whether it is executed.
5. Verify tool scoping:
   - use a low-privilege account and confirm tools cannot perform admin actions.

Practical Burp tips:

- Prefer reversible actions in a test tenant/environment.
- Capture request/response evidence showing the action was executed.

## Vulnerable signals

- The system executes actions without explicit user confirmation.
- The model can request arbitrary tools/arguments with no allowlist.
- Low-privilege users can trigger privileged tool actions.

## Example evidence pattern

- Baseline: agent proposes an action but waits for confirmation.
- Attack: agent executes the action immediately (or via indirect injection) without approval.

## Source code examples

```python
# Vulnerable
def execute_agent_action(action_request):
    os.system(action_request.command)

# Controlled
def execute_agent_action(action_request):
    allowed_tools = {'get_weather': get_weather, 'search_docs': search_docs}
    if action_request.tool_name in allowed_tools:
        return allowed_tools[action_request.tool_name](action_request.params)
    raise SecurityError('Agent requested an unauthorized or unsafe action')
```

## Validation notes

- Only report excessive agency when you can show a concrete unauthorized action path.
- Include the missing gate (no confirmation, no allowlist, over-privileged identity) in the finding.

## Control-level mitigations (no patch code)

- Tool allowlists and schema validation for arguments.
- Use scoped identities for tools (least privilege per capability).
- Require user confirmation/step-up auth for high-impact actions.
- Add audit logs, rate limits, and kill switches.
