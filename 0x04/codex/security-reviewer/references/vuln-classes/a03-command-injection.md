# A03 Command Injection

## What it is
Command injection occurs when untrusted data is interpreted by a shell or is allowed to control a privileged OS command.
It commonly becomes **remote code execution (RCE)**, data theft, or lateral movement.

## What it is NOT (common false positives)
- **Not SQL injection**: SQLi targets database query construction.
- **Not code injection**: code injection executes language/runtime code (eval/exec), not OS commands.
- **Not SSRF**: SSRF abuses server-side network requests; command injection abuses OS command execution.
- **Not inherently vulnerable to use `subprocess.run([...], shell=False)`** if arguments are fixed/validated and the user
    cannot control dangerous flags.

## Common variants
- **Shell command injection**: attacker-controlled text becomes part of a shell command string (metacharacters get interpreted).
- **Argument injection**: even without a shell, attacker controls flags/arguments to a powerful binary (you may be “granting” the tool).
- **Executable/path injection**: attacker influences which binary runs (PATH, working dir, env vars, user-supplied executable).
- **Blind command injection**: the command runs but output is not returned (async jobs, logging-only flows).

## Review checklist (sources → sinks)
Common sources:
- Query params / JSON fields like `cmd`, `args`, `target`, `hostname`, `path`
- CI variables, config files, “admin tools” endpoints

Common sinks (high risk):
- Python: `os.system`, `os.popen`, `subprocess.*(shell=True)`, `"sh -c"` wrappers
- Node: `child_process.exec`, `spawn('sh', ['-c', ...])`
- Java: `Runtime.exec("sh -c ...")`, `ProcessBuilder("sh", "-c", ... )`

Controls:
- Prefer **no shell** (`shell=False`) and pass args as an explicit list.
- Don’t expose “free-form flags/args” to users; map **modes → fixed arguments**.
- Validate targets (IP/hostname/path) and reject unexpected characters (spaces, newlines) and leading `-`.
- Where supported, pass `--` before user-controlled args to prevent option injection.
- Use strict timeouts; run with least privilege.

## Validation notes (safe)
- Prove the input crosses into a shell or controls dangerous flags.
- For blind cases, identify **observable side effects** (files, logs, outbound requests, timing differences) and the execution context.

## Examples

### Shell command injection (in-band stdout)

```python
# Vulnerable (string command executed via shell)
import os

def ping_target(ip_address):
    return os.popen(f'ping -c 1 {ip_address}').read()

# Controlled (no shell; explicit args)
import subprocess

def ping_target(ip_address):
    result = subprocess.run(
        ['ping', '-c', '1', ip_address],
        capture_output=True,
        text=True,
        timeout=5,
        shell=False,
    )
    return result.stdout
```

### Blind command injection (async/background execution)

```python
# Vulnerable (queued job, output not returned)
import subprocess

@app.post('/api/scan')
@require_auth
def scan():
    target = request.json['target']
    subprocess.Popen(f'ping -c 1 {target}', shell=True)  # blind shell injection
    return {'queued': True}, 202

# Controlled (validate input + no shell)
import ipaddress

def require_ip(target: str) -> str:
    ipaddress.ip_address(target)  # raises ValueError on invalid input
    return target

@app.post('/api/scan')
@require_auth
def scan():
    target = require_ip(request.json['target'])
    subprocess.Popen(['ping', '-c', '1', target], shell=False)
    return {'queued': True}, 202
```

### Argument injection (unsafe exposure of tool flags)

```python
# Vulnerable (user controls tool flags; even without a shell, this can be dangerous)
import subprocess

@app.post('/api/diagnostic')
@require_auth
def diagnostic():
    tool = request.json['tool']
    flags = request.json.get('flags', [])  # attacker-controlled
    target = request.json['target']
    subprocess.run([tool, *flags, target], check=True, timeout=30, shell=False)
    return {'ok': True}

# Controlled (mode allowlist; no arbitrary flags)
ALLOWED_TOOLS = {
    'ping1': ['ping', '-c', '1'],
    'trace': ['traceroute', '-m', '8'],
}

@app.post('/api/diagnostic')
@require_auth
def diagnostic():
    mode = request.json['mode']
    target = request.json['target']
    base = ALLOWED_TOOLS.get(mode)
    if base is None:
        abort(400, 'Unsupported mode')
    subprocess.run([*base, target], check=True, timeout=30, shell=False)
    return {'ok': True}
```
