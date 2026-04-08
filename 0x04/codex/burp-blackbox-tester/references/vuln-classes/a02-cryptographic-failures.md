# A02 Cryptographic Failures

## What it is

Cryptographic failures happen when an application:

- transmits sensitive data without adequate transport security,
- uses weak or misconfigured cryptography,
- mishandles secrets/tokens (integrity, scope, replay, expiry), or
- exposes sensitive data due to missing integrity protections.

In black-box testing, focus on what you can prove from HTTP behavior and observable side effects.

## What it is NOT (common false positives)

- **Not “base64 is encryption”**: base64 is an encoding.
- **Not “a JWT exists, therefore it’s vulnerable”**: most JWTs are fine; you need a concrete bypass.
- **Not usually provable from black-box:** password hashing choices, key management practices, and crypto-at-rest details often require code/config access.

## Where it shows up (black-box)

- **Transport:** sensitive endpoints reachable over HTTP, weak HTTP→HTTPS redirects, missing HSTS.
- **Cookies:** session/auth cookies missing `Secure`, `HttpOnly`, or an appropriate `SameSite`.
- **Tokens:** bearer tokens or JWTs that can be tampered with or replayed across contexts.
- **Account recovery:** password reset/magic links that are reusable, long-lived, or guessable.
- **Client-side state:** opaque “encrypted” or “signed” blobs in cookies/params that fail open on tamper.

## Black-box probe strategy (Burp MCP)

### 1) Transport and cookie security (low impact)

1. Attempt the same endpoint over `http://` and `https://`.
2. Confirm the server strictly redirects to HTTPS for sensitive paths.
3. Inspect response headers for:
   - `Strict-Transport-Security` (HSTS)
   - `Set-Cookie` flags: `Secure`, `HttpOnly`, `SameSite`
4. For authenticated flows, confirm cookies are not issued over HTTP.

### 2) Token integrity and tamper resistance

1. Identify auth artifacts (bearer token, session cookie, JWT).
2. Perform a minimal tamper test:
   - change a single character in the token/cookie value,
   - resend the same request,
   - confirm the server fails closed (typically `401`/`403` with an “invalid token/signature” style error).
3. If the token looks like a JWT, attempt a claim modification (for example `role`, `sub`, `tenantId`) **without** re-signing.
   - Vulnerable behavior requires acceptance of the modified token.

### 3) Replay, scope, and expiry behavior

- Try replaying a token/cookie across:
  - two different users,
  - two different tenants/orgs,
  - or two different sessions,
  and observe whether access control decisions correctly change.
- Validate expiry by waiting for expected timeouts (or using known-expired tokens if the system issues them).

### 4) Account recovery (reset links / magic links)

1. Request multiple reset links for the same account and compare token formats/lengths.
2. Verify one-time use:
   - use the link once successfully,
   - attempt to reuse it (should fail).
3. Verify token binding:
   - if you have multiple accounts, attempt to use account A’s token in a context for account B.

Avoid brute force. Prefer entropy/predictability observations and “reuse still works” checks.

### 5) Encrypted/signed client-side state

If you see opaque blobs like `state=...`, `data=...`, `payload=...` in cookies/params:

- Copy the value between accounts and check whether it is accepted.
- Mutate the value slightly and confirm the server rejects it.
- Prefer “fail closed” validation (clear rejection) over noisy tamper that could trigger account locks.

## Vulnerable signals

- Sensitive endpoints are reachable over HTTP or can be downgraded.
- Missing HSTS on the primary production domain.
- Session/auth cookies missing `Secure` and/or `HttpOnly`.
- Token/cookie tampering is accepted or degrades into a weaker mode.
- Reset links are reusable or remain valid far longer than expected.
- Tokens appear predictably structured (very short, timestamp-like, sequential) across multiple issuances.

## Example evidence pattern

### Insecure cookie flags

Baseline response:

```http
HTTP/1.1 200 OK
Set-Cookie: session=<redacted>; Path=/; SameSite=Lax
```

Observation:

- Cookie lacks `Secure` and `HttpOnly` despite being a session/auth token.

### Password reset token reuse

1. Request password reset for `userA@example.test`.
2. Use the reset link once (success).
3. Reuse the same reset link (should fail).

Evidence to capture:

- Reset-request baseline (redacted) and the reset-submit request.
- The second reset-submit attempt showing reuse is still accepted.

## Source code examples

```javascript
// Vulnerable (illustrative): session cookie without secure flags
res.cookie('session', token);

// Controlled (illustrative): enforce secure cookie flags
res.cookie('session', token, {
  secure: true,
  httpOnly: true,
  sameSite: 'lax',
});
```

```python
# Vulnerable (illustrative): reset tokens that can be reused
def reset_password(token, new_password):
    user = lookup_user_by_token(token)
    user.set_password(new_password)
    db.commit()

# Controlled (illustrative): one-time tokens + expiry + invalidation
def reset_password(token, new_password):
    user = lookup_user_by_token(token)
    require_not_expired(token)
    require_not_used(token)
    user.set_password(new_password)
    mark_token_used(token)
    db.commit()
```

## Validation notes

- Be explicit about environment: HSTS and cookie flags often differ between dev/staging/prod.
- Do not claim “weak hashing” or “bad key management” from black-box unless you have direct evidence.
- For tamper tests, confirm the server rejects the modified token consistently (repeat runs).

## Control-level mitigations (no patch code)

- Enforce HTTPS everywhere; redirect HTTP→HTTPS for all sensitive routes.
- Enable HSTS on production domains.
- Set appropriate cookie flags (`Secure`, `HttpOnly`, `SameSite`) for session/auth cookies.
- Use short-lived tokens with strict audience/issuer validation and robust signature verification.
- Make recovery tokens one-time and short-lived; invalidate on use and on key account events.
- Generate tokens using cryptographically secure RNG with sufficient entropy.
