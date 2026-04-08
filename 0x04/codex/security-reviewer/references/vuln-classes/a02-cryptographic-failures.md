# A02 Cryptographic Failures

## What it is
Cryptographic failures are weaknesses in encryption, hashing, key management, TLS usage, or randomness
that enable data exposure, credential compromise, or integrity bypass.

## What it is NOT (common false positives)
- **Not encoding**: Base64/hex/url-encoding are reversible and provide no secrecy.
- **Not “we use HTTPS”** if certificate validation is disabled or plaintext endpoints are still available.
- **Not solved by “encrypting” without integrity**: confidentiality without authentication can be malleable.
- **Not the same as authorization** (IDOR/BOLA and broken function-level auth are access control issues).

## Common variants

### Password storage
- Using fast hashes for passwords (MD5/SHA1/SHA256) instead of a password KDF.
- Missing per-user salts or using a single global salt.
- Weak parameters (low cost factors) or legacy algorithms.

### Tokens and randomness
- Weak RNG (`random.random`, `Math.random`) used for secrets/tokens.
- Short, guessable tokens; missing expiry; tokens not scoped to an action or user.

### TLS misuse
- Disabling TLS verification (`verify=False`) or accepting self-signed certs in production.
- Skipping hostname validation.

### Encryption misuse
- Encryption without authentication (non-AEAD used incorrectly).
- Static IV/nonce reuse.
- Homegrown crypto implementations.

### Key management
- Hard-coded keys in source code.
- Keys stored alongside ciphertext with no separation.
- No rotation/revocation path.

## Review checklist
Look for:
- Password hashing: `md5`, `sha1`, `sha256(password)` patterns
- Encryption without authentication (no AEAD), custom crypto, ECB mode
- TLS calls with verification disabled
- Token generation using non-CSPRNG sources
- Keys and secrets stored in repos, images, logs, or configs

Controls:
- Passwords: `bcrypt/scrypt/argon2` with per-password salts and sane parameters.
- Secrets/keys: rotate, store in KMS/Vault, avoid logging.
- TLS: verification on, pinning only when operationally justified.
- Tokens: use CSPRNG (`secrets` in Python, `crypto.randomBytes` in Node).
- Encryption: prefer vetted AEAD modes (AES-GCM / ChaCha20-Poly1305).

## Validation notes (safe)
- For password hashing, confirm stored hashes are fast/unsalted and feasible to crack offline.
- For TLS/crypto misuse, show how confidentiality/integrity assumptions fail.

## Examples

```python
import hashlib
import random
import secrets

# Vulnerable: fast hash for passwords
password_hash = hashlib.md5(password.encode()).hexdigest()

# Vulnerable: weak randomness for tokens
token = str(random.random())

# Controlled: slow password hashing (illustrative)
from werkzeug.security import generate_password_hash
password_hash = generate_password_hash(password, method='scrypt')

# Controlled: CSPRNG token
token = secrets.token_urlsafe(32)
```
