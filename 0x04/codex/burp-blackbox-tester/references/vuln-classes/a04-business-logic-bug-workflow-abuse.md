# A04 Business Logic Bug (Workflow Abuse)

## What it is

Business logic bugs occur when valid endpoints can be combined in an invalid sequence to break intended rules, such as pricing, approval, or settlement flows.

## What it is NOT (common false positives)

- Client-side UI glitches where the server state remains correct (verify server-side state).
- A discounted UI price where the server re-calculates and charges the correct total.
- A rejected transition that returns `200` with an error object (verify side effects).

## Black-box probe strategy (Burp MCP)

1. Map core workflows (quote, checkout, payment, refund, role approval).
2. Replay requests out of order or with stale identifiers.
3. Tamper with client-supplied fields that should be server-authoritative (price, role, status).
4. Verify whether server accepts impossible transitions.

Practical Burp tips:

- Capture the **whole workflow** once (end-to-end) to understand the intended state machine.
- Then isolate the “authoritative” server checks by replaying only the final step with manipulated inputs.
- Prefer low-impact proof (sandbox carts, test payments, non-financial endpoints) whenever possible.

## Vulnerable signals

- Checkout finalizes with manipulated amount.
- Refund executes multiple times for one settled transaction.
- Approval-only action succeeds without prior required state.

## Example evidence pattern

- Baseline: finalize uses server-calculated total.
- Attack: finalize accepts client total (or skips required approval state).
- Proof: order/receipt reflects the manipulated total or impossible state.

## Example attack request

```http
POST /api/v1/checkout/finalize HTTP/1.1
Host: app.example.test
Authorization: Bearer <token>
Content-Type: application/json

{"quoteId":"q_1299","total":"0.01"}
```

## Source code examples

```python
# Vulnerable: server trusts client-provided final total
@app.post('/api/v1/checkout/finalize')
def finalize():
    total = Decimal(request.json['total'])
    quote_id = request.json['quoteId']
    payments.charge(current_user.id, total)
    orders.complete_from_quote(quote_id, total)
    return {'ok': True}

# Controlled: final total is recalculated from server-side quote state
@app.post('/api/v1/checkout/finalize')
def finalize():
    quote_id = request.json['quoteId']
    total = pricing.calculate_authoritative_total(quote_id, current_user.id)
    payments.charge(current_user.id, total)
    orders.complete_from_quote(quote_id, total)
    return {'ok': True}
```

## Validation notes

- Demonstrate business invariant failure with before and after state.
- Keep proof low-impact when real payment or account effects are involved.

## Control-level mitigations (no patch code)

- Treat client inputs as hints; compute authoritative totals/status server-side.
- Enforce workflow state transitions on the server (state machine + invariant checks).
- Add audit logging for sensitive transitions and anomaly detection.
