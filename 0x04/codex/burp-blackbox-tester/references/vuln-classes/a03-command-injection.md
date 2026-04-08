# A03 Command Injection

## What it is

Command injection occurs when untrusted data is interpreted by a shell or is allowed to control a privileged OS command.
In practice, it can become remote code execution (RCE), data theft, or lateral movement.

## What it is NOT (common false positives)

- Not SQL injection: SQLi targets database query construction.
- Not code injection: code injection executes language/runtime code (eval/exec), not OS commands.
- Not SSRF: SSRF abuses server-side network requests; command injection abuses OS command execution.
- Not inherently vulnerable to running OS commands if user input cannot influence the command or its arguments.

## Black-box probe strategy (Burp MCP)

1. Identify features likely to spawn OS commands:
   - diagnostics (ping/traceroute/dns lookup),
   - file conversion (image/PDF),
   - backup/restore/export,
   - Git/webhook testing utilities,
   - “admin tools” that accept `path`, `host`, `target`, `args`, or `format`.
2. Capture a baseline request that triggers the operation.
3. Test for command parsing with minimal, low-impact probes:
   - metacharacter separators (`;`, `|`, `&&`),
   - newline injection (`%0a`),
   - option/argument injection (values starting with `-`).
4. Validate with at least two independent signals when possible:
   - response delta (error/output changes),
   - timing delta (small 2–3 second delay),
   - out-of-band callback (Burp Collaborator) for blind cases.

Practical Burp tips:

- Keep a baseline Repeater tab and clone it for payload variations so cookies/headers remain identical.
- Prefer time-based or OOB proof over “weird error messages” alone.
- Avoid destructive payloads. Prove control, then stop.

## Vulnerable signals

- The response includes command output or clearly changes based on shell metacharacters.
- A consistent timing delta appears only for the injected case.
- Burp Collaborator receives a DNS/HTTP interaction triggered by your request (blind command injection).
- Error messages reference shell parsing or OS command execution.

## Payload ideas (low-impact first)

- Metacharacter presence tests: `;`, `|`, `&&`, `%0a`
- Argument injection tests: leading `-`, `--help`, unexpected flags
- Timing proof (keep delays small):
  - Unix-like: `; sleep 2`
  - Windows-like: `& timeout /t 2`

Avoid data-exfiltration payloads unless explicitly authorized.

## Example attack request

```http
POST /api/v1/diagnostics/ping HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Content-Type: application/json

{"target":"127.0.0.1; sleep 2"}
```

## Example evidence pattern (time-based)

Baseline:

```http
POST /api/v1/diagnostics/ping HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Content-Type: application/json

{"target":"127.0.0.1"}
```

Injected (delay):

```http
POST /api/v1/diagnostics/ping HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Content-Type: application/json

{"target":"127.0.0.1; sleep 2"}
```

If the injected request reliably adds ~2 seconds (repeat 3–5 times) while the baseline does not, and no other variables changed, command injection is likely.

## Source code examples

```python
# Vulnerable (string executed via shell)
import os

def ping_target(ip_address: str) -> str:
    return os.popen(f'ping -c 1 {ip_address}').read()

# Controlled (no shell; explicit args)
import subprocess

def ping_target(ip_address: str) -> str:
    result = subprocess.run(
        ['ping', '-c', '1', ip_address],
        capture_output=True,
        text=True,
        timeout=5,
        shell=False,
        check=False,
    )
    return result.stdout
```

## Validation notes

- Prove the behavior is payload-dependent and repeatable.
- Rule out WAF blocks by using a second, distinct payload (for example metacharacter vs timing).
- Avoid triggering background jobs repeatedly; confirm once, then stop.

## Control-level mitigations (no patch code)

- Avoid shells; pass arguments as an explicit list.
- Do not expose free-form `cmd`/`args` to users; map modes to fixed arguments.
- Validate inputs (host/path) and reject dangerous characters and leading `-`.
- Use strict timeouts and least-privilege execution contexts.
