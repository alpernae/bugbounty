# LLM08 Excessive Agency

## What it is
Excessive agency occurs when an LLM/agent can take high-impact actions (execute commands, mutate data, spend money,
deploy changes, access sensitive systems) without strong guardrails, approvals, or least-privilege tool access.

This is a capability/security boundary issue: what the model *can do*, not what it *says*.

## What it is NOT (common false positives)
- An assistant that only provides suggestions (no tool execution) is usually not “agentic,” though it may still have other risks.
- Normal automation with strict allowlists, approvals, and auditing is not excessive agency.
- Read-only tools are lower risk (but still can lead to disclosure depending on data access).

## Common variants
- Agents that can run arbitrary shell/SQL/HTTP requests from model output.
- Broad “admin” tools exposed to the model with weak policy checks.
- Automatic action execution without user confirmation.
- Agents that can write files/configs and then run them.
- Long-running agent loops that keep retrying until an action succeeds.

## Review checklist
Look for:
- Tool routers that accept arbitrary tool names/args
- Shell command execution, file writes, network calls without allowlists
- Over-privileged API keys/credentials used by the agent
- Lack of audit logs for agent actions
- No “step-up” or confirmation for high-impact actions

## Controls
- Tool allowlists and schema validation for arguments.
- Use scoped identities for tools (least privilege per capability).
- User confirmation/step-up auth for high-impact actions.
- Strict separation between “suggest” and “execute”.
- Global safety rails: rate limits, time limits, and kill switches.

## Validation notes (safe)
- Prove the model can trigger an unauthorized tool/action through prompt injection or malformed tool calls.
- Identify the high-impact capability reachable and the missing gate.

## Examples

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
