# Zero Trust: Least Privilege Identity

## What it is

Least privilege means each component runs with the minimum permissions required.
Over-privileged identities (DB superusers, broad cloud roles, shared API keys) turn small bugs into full compromise.

## What it is NOT (common false positives)

- Not “no permissions”: the goal is minimum necessary, not zero.
- Not solved by network isolation alone: once code execution happens, credentials/roles often matter more.
- Not a one-time setup: permissions drift; rotation and audits are required.

## Black-box probe strategy (Burp MCP)

Black-box testing cannot directly read IAM policies, but you can still identify symptoms of over-privilege.

1. Look for leaked credentials in client-accessible places:
   - JavaScript bundles, mobile configs, error messages,
   - API responses that contain keys/tokens,
   - webhooks/integrations pages that expose secrets.
2. When you find a credential, validate scope safely:
   - attempt a read-only call vs a write/admin call,
   - confirm whether one key grants broad access across tenants or environments.
3. If the application can reach cloud metadata services via SSRF (see SSRF class), treat it as a potential privilege escalation path.
4. Document blast radius:
   - what data/actions become possible if the service identity is compromised.

## Vulnerable signals

- A single credential grants read/write/admin across multiple resources or tenants.
- The same key appears to work across environments (dev/stage/prod).
- Low-privilege user contexts can trigger high-privilege actions (boundary collapse).

## Example evidence pattern

- Discovered key in a client bundle or response.
- Verified the key can perform an admin-only action (in a controlled test tenant/environment).

Redact secrets in all evidence.

## Source code examples

```python
# Vulnerable (illustrative)
db_connection = psycopg2.connect(user='postgres_superuser', password=global_pass)

# Controlled (illustrative)
db_connection = psycopg2.connect(
    user='scoped_service_role',
    password=get_rotated_credential_from_vault('scoped_service_role'),
)
```

## Validation notes

- Only validate privileges you are authorized to test.
- Prefer demonstrating “this key can do X it should not” over enumerating all permissions.

## Control-level mitigations (no patch code)

- Use scoped roles/identities per service and per environment.
- Separate read-only and write identities.
- Use short-lived credentials via a secret manager; rotate and audit.
- Restrict high-impact operations with additional authorization and strong service identity.
