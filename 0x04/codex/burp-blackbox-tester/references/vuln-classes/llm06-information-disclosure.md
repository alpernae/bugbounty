# LLM06 Information Disclosure

## What it is

Information disclosure occurs when sensitive data (PII, secrets, internal documents, credentials)
enters prompts or is emitted by the model without adequate controls.

The most important cases are cross-boundary leaks: one user/tenant receiving another’s data,
or a low-privilege user receiving privileged/internal material.

## What it is NOT (common false positives)

- The model hallucinating information that is not actually present.
- Public information being repeated.
- Authorized operators viewing internal instructions in a controlled environment (scope matters).

## Black-box probe strategy (Burp MCP)

1. Identify whether RAG/document retrieval exists:
   - “search answers”, “knowledge base”, “summarize documents”, “chat with files”.
2. Test authorization boundaries with safe canaries:
   - seed a unique, non-sensitive canary string in tenant A,
   - query from tenant B and confirm it is not retrievable.
3. Check for cache boundary issues:
   - run the same query as two different users/tenants,
   - ensure responses do not leak prior user context.
4. Test for prompt/system disclosure:
   - attempt to get the model to reveal hidden prompts or tool outputs,
   - report only when sensitive content is actually disclosed.

Practical Burp tips:

- Capture full prompts/responses and redact sensitive values.
- Include the boundary in the finding (user → user, tenant A → tenant B, user → admin).

## Vulnerable signals

- The model returns another tenant’s documents or snippets.
- Responses contain secrets that should never leave the server (tokens, API keys).
- Tool outputs containing sensitive data are printed verbatim to the user.

## Example evidence pattern

- Baseline: tenant A query returns only tenant A content.
- Attack: tenant B query returns tenant A canary content.

## Source code examples

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

## Validation notes

- Prove the sensitive material was present and crossed a real authorization boundary.
- Prefer canaries over real PII/secrets for testing.

## Control-level mitigations (no patch code)

- Minimize sensitive context and redact before prompting.
- Enforce per-document/user authorization checks in retrieval.
- Partition indexes/caches by tenant/user and include tenant in cache keys.
- Filter outputs for secrets/PII patterns and avoid logging sensitive prompts.
