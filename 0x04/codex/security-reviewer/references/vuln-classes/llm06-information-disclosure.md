# LLM06 Information Disclosure

## What it is
Information disclosure occurs when sensitive data (PII, secrets, internal documents, credentials)
is placed into prompts or is emitted by the model without adequate controls.

The most important cases are cross-boundary leaks: one user/tenant receiving another’s data, or a low-privilege
user receiving privileged/internal material.

## What it is NOT (common false positives)
- The model “making something up” (hallucination) that is not actually present.
- Public information being repeated.
- Internal instructions being visible to authorized operators in a controlled environment (still may be undesirable, but scope matters).

## Common variants
- RAG retrieval returns documents outside the user’s authorization scope.
- Prompt contains secrets (API keys, tokens) and model is asked to “summarize” or “debug”.
- Model outputs hidden system instructions, tool results, or private context.
- Cross-tenant caching bugs (same cache key used for different users/tenants).
- Tool integrations return sensitive data and the model prints it verbatim.
- Long-term memory stores sensitive data and is later shown in unrelated conversations.

## Review checklist
Look for:
- LLM prompts built from raw customer records, logs, tickets, emails
- Lack of per-document/user authorization checks in retrieval pipelines
- Weak tenant separation (cache keys, indexes, embedding stores)
- No output filtering/redaction for secrets/PII patterns
- Debug logging of prompts/responses containing sensitive data

## Controls
- Minimize sensitive context; apply authz filters in retrieval.
- Redact/transform PII before prompting and filter outputs for secrets.
- Use least-privilege API keys and avoid long-lived credentials.
- Partition retrieval indexes by tenant; ensure cache keys include tenant/user context.

## Validation notes (safe)
- Prove that sensitive material can enter the prompt or exit in responses across an auth boundary.
- Identify the source (RAG doc, tool output, memory, logs) and the boundary crossed.

## Examples

```python
# Vulnerable: no per-document authorization
doc = rag.retrieve(query, top_k=5)
response = llm.complete(f'Context: {doc.text}')

# Controlled: enforce authz + redact
docs = rag.retrieve(query, top_k=5)
docs = [d for d in docs if user_can_access(user, d)]
context = redact_pii('\n\n'.join(d.text for d in docs))
response = llm.complete(f'Context: {context}')
return filter_sensitive_output(response)
```
