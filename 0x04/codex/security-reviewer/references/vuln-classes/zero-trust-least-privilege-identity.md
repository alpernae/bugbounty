# Zero Trust: Least Privilege Identity

## What it is
Least privilege means each component runs with the minimum permissions required.
Over-privileged identities (DB superusers, broad cloud roles) turn small bugs into full compromise.

## What it is NOT (common false positives)
- **Not “no permissions”**: the goal is minimum necessary, not zero.
- **Not solved by network isolation** alone: once code execution happens, credentials/roles often matter more.
- **Not a one-time setup**: permissions drift; rotation and audits are required.

## Common variants
- Using admin/superuser DB credentials in application code.
- One shared credential across multiple services/environments.
- Long-lived secrets stored in env vars or config files without rotation.

Additional common variants:
- Wildcard cloud permissions (`*`) granted to runtime identities.
- Kubernetes service accounts with cluster-admin.
- Same API keys reused for read and write paths.

## Review checklist
Look for:
- DB connections using superuser roles
- Cloud SDK credentials with broad permissions
- Secrets embedded in code/config and reused across components

Also look for:
- Break-glass/admin credentials used in normal runtime paths.
- Lack of separation between dev/staging/prod identities.
- Missing rotation / revocation for leaked credentials.

Controls:
- Create scoped service roles (read-only vs write vs admin) and rotate credentials via a secret manager.
- Use short-lived tokens where possible and audit privileged operations.
- Use separate identities per service and per environment.
- Prefer narrowly scoped, time-bound access for maintenance.

## Validation notes (safe)
- Identify what an attacker could do with the service identity if they gain code execution.

```python
# Vulnerable
db_connection = psycopg2.connect(user='postgres_superuser', password=global_pass)

# Controlled
db_connection = psycopg2.connect(
    user='read_only_service_role',
    password=get_rotated_credential_from_vault('read_only_service_role'),
)
```
