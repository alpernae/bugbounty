# A04 Insecure Design (TOCTOU)

## What it is
TOCTOU (Time-of-Check to Time-of-Use) flaws occur when code checks a condition and then acts on it later,
without enforcing atomicity. Under concurrency, attackers can win races (double-spend, exceed limits).

## What it is NOT (common false positives)
- **Not “any concurrent requests”**: TOCTOU requires a check/use gap where the invariant can be violated.
- **Not purely a performance issue**: it is an integrity/authorization/invariant enforcement problem.
- **Not always fixed by rate limiting**: attackers can still win races under low rates.
- **Not the same as business logic bugs** (though TOCTOU often enables business-logic abuse).

## Common variants
- Inventory/coupon/credits counters checked then decremented without locking.
- “Check permission” then “use resource” with a gap across threads/processes.
- Distributed race conditions when multiple workers update the same record.

Additional common variants:
- Double-spend on wallet/balance updates.
- Multiple redemptions of a “one time” token.
- Parallel order finalization (duplicate charge / duplicate shipment).

## Review checklist
Look for patterns like:
- `if allowed(): do_action(); update_state()` with separate DB reads/writes
- Missing transactions, missing unique constraints, missing row locks

Controls:
- Use atomic DB operations: transactions + row locks (`SELECT ... FOR UPDATE`) or atomic `UPDATE ... WHERE ...`.
- Add constraints to enforce invariants even under race.
- Prefer single-statement conditional updates with a checked rowcount.

## Validation notes (safe)
- Show the invariant that can be broken (uses_left < 0, negative balance, duplicate redemption).
- Identify realistic concurrency primitives (parallel requests, multi-worker queues).

```python
# Vulnerable
@app.route('/api/apply_coupon', methods=['POST'])
@require_auth
def apply_coupon():
    coupon = Coupon.query.get(request.json['coupon_id'])
    if coupon.uses_left > 0:
        apply_discount(current_user, coupon)
        coupon.uses_left -= 1
        db.session.commit()
    return 'Coupon applied'

# Controlled
@app.route('/api/apply_coupon', methods=['POST'])
@require_auth
def apply_coupon():
    coupon = Coupon.query.with_for_update().get(request.json['coupon_id'])
    if coupon.uses_left > 0:
        apply_discount(current_user, coupon)
        coupon.uses_left -= 1
        db.session.commit()
        return 'Coupon applied'
    return 'Coupon exhausted', 400
```

```sql
-- Controlled pattern (illustrative)
-- Atomically decrement only if there are uses left
UPDATE coupons
SET uses_left = uses_left - 1
WHERE id = :coupon_id AND uses_left > 0;
-- Check affected row count == 1 to confirm success
```
