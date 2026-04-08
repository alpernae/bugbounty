# Black-Box Security Report Template

Use this structure for each validated black-box finding.

## Markdown Template

````md
# [Vulnerability Title]

## Overview
- Severity: [CVSS score and rating]
- Confidence: [high, medium, low]
- Category: [OWASP or custom class]
- Affected Endpoint: [method and path]
- Discovery Date: [YYYY-MM-DD]

## Scope and Preconditions
- Target: [base URL or component]
- Required role or auth state: [anonymous, user, admin]
- Preconditions: [account state, feature flag, known object id]

## Summary
[Root cause behavior from black-box perspective, trust boundary crossed, and exploitability conditions.]

## Reproduction (Burp MCP)
1. [Baseline request]
2. [Mutation or payload]
3. [Observed response delta]
4. [Repeatability check]

## Raw HTTP Evidence
### Request
```http
[raw request]
```

### Response Excerpt
```http
[status line, relevant headers, and body excerpt]
```

## Impact
[Technical and business impact, including what an attacker can do in practice.]

## Recommendations
[Control-level fixes and architecture controls. No patch code.]

## References
- [Reference 1]
- [Reference 2]
````

## Report File Path

- audit/blackbox/YYYY-MM-DD-target-review.md

## Required Footer

- Scope reviewed
- Assumptions made
- Coverage and testing gaps
- Prioritized remediation order
