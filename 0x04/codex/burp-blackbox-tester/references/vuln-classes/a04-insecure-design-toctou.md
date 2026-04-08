# A04 Insecure Design (TOCTOU)

## What it is

TOCTOU (Time-of-Check to Time-of-Use) flaws occur when the application checks a condition and then acts on it later,
without enforcing atomicity. Under concurrency, attackers can win races (double-spend, exceed limits).

## What it is NOT (common false positives)

- Not “any concurrent requests”: TOCTOU requires a check/use gap where an invariant can be violated.
- Not purely a performance issue: it is an integrity/authorization/invariant enforcement problem.
- Not always fixed by rate limiting: attackers can still win races under low rates.
- Not a single non-reproducible “double success”.

## Black-box probe strategy (Burp MCP)

1. Identify a state-changing request guarded by a limit or invariant:
   - coupon redemption, credits usage, inventory reservation, balance transfer, booking/claim flows.
2. Capture a baseline request and confirm expected behavior (one success consumes the resource).
3. Prepare a burst of identical requests under the same auth context.
4. Send requests concurrently and inspect aggregate effects.
5. Confirm durable backend state:
   - reload account state, inventory count, order list, coupon uses, etc.

Practical Burp tips:

- Use a concurrency-capable tool (Burp extension like Turbo Intruder) when possible.
- If an idempotency key exists, test both:
  - without it (do races occur?),
  - with it (does it correctly collapse duplicates?).

## Vulnerable signals

- More successful operations than allowed by business rules.
- Counters become negative or exceed configured limits.
- Duplicate rewards, purchases, redemptions, or transfers occur from one token/action.

## Example evidence pattern

- Attempts: 20 parallel requests.
- Expected: 1 success.
- Observed: 2+ successes and the backend state reflects multiple commits.

## Example attack request

```http
POST /api/v1/coupons/redeem HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Content-Type: application/json

{"coupon":"SPRING25"}
```

## Source code examples

```sql
-- Controlled pattern (illustrative)
-- Atomically decrement only if there are uses left
UPDATE coupons
SET uses_left = uses_left - 1
WHERE id = :coupon_id AND uses_left > 0;
-- Check affected row count == 1 to confirm success
```

## Validation notes

- Prove the invariant that can be broken (uses_left < 0, duplicate redemption, negative balance).
- Confirm the issue is repeatable (for example reproduced 3/3) and not eventual consistency artifacts.
- Avoid high-volume load tests; keep concurrency bursts small and focused.

## Control-level mitigations (no patch code)

- Enforce atomicity with transactions/locks for contested resources.
- Add server-side uniqueness constraints that make double-commit impossible.
- Use idempotency keys for payment-like or order-like operations.
