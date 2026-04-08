# A04 Race Condition (TOCTOU)

## What it is

A race condition appears when concurrent requests can bypass limits or consistency checks because validation and update are not atomic.

## What it is NOT (common false positives)

- A retry-safe/idempotent endpoint where multiple “200 OK” responses map to a single committed state change.
- Eventual consistency delays that temporarily show duplicated data but later reconcile correctly (still worth noting, but validate the durable state).
- A single “double success” that cannot be reproduced.

## Black-box probe strategy (Burp MCP)

1. Capture a state-changing request guarded by a limit (coupon use, transfer, claim, booking).
2. Prepare a burst of identical requests with the same auth context.
3. Send requests concurrently and inspect aggregate effects.
4. Compare expected single success vs observed multiple successes.

Practical Burp tips:

- If you have a concurrency-capable tool (or Burp extension like Turbo Intruder), use it; otherwise approximate with parallel sends.
- Track an idempotency key header if present; re-run with/without it to understand expected behavior.

## Vulnerable signals

- More successful operations than allowed by business rules.
- Counters become negative or exceed configured limits.
- Duplicate rewards, purchases, or redemptions from one token.

## Example evidence pattern

- Attempts: 20 parallel requests.
- Expected: 1 success.
- Observed: 2+ successes and the backend state reflects multiple redemptions.

## Example attack request

```http
POST /api/v1/coupons/redeem HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Content-Type: application/json

{"coupon":"SPRING25"}
```

## Source code examples

```javascript
// Vulnerable: read-then-write without transaction lock
const coupon = await db.coupons.findById(id);
if (coupon.usesLeft > 0) {
  await db.coupons.update(id, { usesLeft: coupon.usesLeft - 1 });
  await db.redemptions.insert({ userId, couponId: id });
}

// Controlled: transaction and row lock enforce atomicity
await db.transaction(async (tx) => {
  const coupon = await tx.coupons.findByIdForUpdate(id);
  if (coupon.usesLeft <= 0) {
    throw new Error('exhausted');
  }
  await tx.coupons.update(id, { usesLeft: coupon.usesLeft - 1 });
  await tx.redemptions.insert({ userId, couponId: id });
});
```

## Validation notes

- Confirm race behavior is repeatable, not a one-off transport issue.
- Include total attempts and successful responses in evidence.

## Control-level mitigations (no patch code)

- Enforce atomicity with transactions/locks for contested resources.
- Use idempotency keys for payment-like or order-like operations.
- Add server-side uniqueness constraints that make double-commit impossible.
