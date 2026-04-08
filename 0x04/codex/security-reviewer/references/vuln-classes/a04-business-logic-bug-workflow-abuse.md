# A04 Business Logic Bug (Workflow Abuse)

## What it is
Business logic bugs happen when application workflows allow actions that violate business invariants,
even though authentication and basic validation appear to work.

## What it is NOT (common false positives)
- **Not broken access control**: if the issue is “a user can do admin-only action,” that is authorization.
- **Not TOCTOU by default**: races are a common cause, but workflow abuse can be purely sequential.
- **Not injection**: business logic bugs are usually about missing invariants/state transitions, not parsing.
- **Not “user can do a thing”** unless it violates an intended business rule (invariant).

## Common variants
- Applying discounts after checkout finalization.
- Cancelling fulfilled orders without reconciliation.
- Bypassing approval steps by calling later workflow endpoints directly.
- Combining valid actions in an invalid sequence to gain financial or privilege advantage.

Additional common variants:
- Negative quantity/amount edge cases (refunds, credits, wallets).
- Coupon stacking / multiple redemptions due to missing constraints.
- Missing idempotency controls (double charge, double refund, duplicate redemption).
- Trusting client-supplied price/tax/shipping after server-side quote.
- Privileged workflow abuse (support tools, admin overrides) missing additional checks/audit.

## Review checklist
Look for:
- Missing state-machine validation (`pending -> approved -> settled`).
- Endpoints that assume previous checks happened elsewhere.
- Price, quantity, or fee fields trusted from client after server-side calculation.

Also look for:
- Any “finalize/commit” endpoint that does not re-check invariants.
- Invariant enforcement split across services without a single source of truth.
- Missing uniqueness constraints (e.g., “coupon can be used once”).
- Missing idempotency keys for payment-like operations.

Controls:
- Enforce workflow transitions server-side with explicit state validation.
- Recompute sensitive values server-side at finalization.
- Log and reject impossible state transitions.
- Add database constraints/unique indexes to enforce “at most once” invariants.
- Use idempotency keys for charge/refund/fulfillment style actions.

## Validation notes (safe)
- Demonstrate a violated invariant (free purchase, double refund, unauthorized transition).
- Provide the exact valid calls that become dangerous in sequence.

## Additional example: double refund without idempotency

```python
# Vulnerable (replays/refires cause duplicate refund)
@app.post('/api/refund')
@require_auth
def refund():
    order_id = request.json['order_id']
    refund_provider(order_id)
    mark_refunded(order_id)
    return {'ok': True}

# Controlled (illustrative: require idempotency key + enforce uniqueness)
@app.post('/api/refund')
@require_auth
def refund():
    order_id = request.json['order_id']
    key = request.headers.get('Idempotency-Key')
    if not key:
        abort(400, 'Missing Idempotency-Key')
    ensure_not_used_before(current_user.id, key)  # unique constraint
    refund_provider(order_id)
    mark_refunded(order_id)
    return {'ok': True}
```

```python
# Vulnerable: finalize trusts client total after quote creation
@app.post('/api/checkout/finalize')
def finalize_checkout():
    cart_id = request.json['cart_id']
    submitted_total = Decimal(request.json['total'])
    charge_customer(current_user.id, submitted_total)
    mark_order_paid(cart_id, submitted_total)
    return {'ok': True}

# Controlled: total is recomputed server-side from authoritative cart data
@app.post('/api/checkout/finalize')
def finalize_checkout():
    cart_id = request.json['cart_id']
    authoritative_total = pricing_service.calculate_total(cart_id, current_user.id)
    charge_customer(current_user.id, authoritative_total)
    mark_order_paid(cart_id, authoritative_total)
    return {'ok': True}
```
