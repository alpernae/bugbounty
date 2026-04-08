# Project Memory

## Target Profile

- Name: [target name]
- Base URLs: [list]
- App type: [web app, API, mixed]
- Critical assets: [accounts, payments, secrets, admin actions]

## Scope Source

- Program scope file: .github/SCOPE.md
- Last scope verification date: [YYYY-MM-DD]
- Out-of-scope constraints: [list]

## Access and Test Identities

| Role | Account | Notes | Last Verified |
| --- | --- | --- | --- |

## Endpoint Inventory

| Method | Path | Auth Context | Risk Tag | Last Tested |
| --- | --- | --- | --- | --- |

## Findings Registry

| ID | Fingerprint | Category | Severity | Confidence | Status | Endpoint | Last Updated |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Finding Details

### FIND-YYYY-MM-DD-001

- fingerprint: [category|endpoint|vector|control_gap]
- category: [category]
- severity: [severity]
- confidence: [confidence]
- status: [open|validated|in_progress|mitigated|risk_accepted|false_positive|duplicate]
- endpoint: [method and path]
- exploit_path: [request mutation and observed effect]
- evidence:
  - [request id, endpoint, or log reference]
- impact: [technical and business]
- last_updated: [YYYY-MM-DD]

## Session Notes

- Anti-automation controls observed: [captcha, rate limits, WAF behavior]
- Session handling quirks: [token rotation, CSRF model, cookie flags]

## Review History

| Date | Branch | Commit | Scope | Reviewer | Summary |
| --- | --- | --- | --- | --- | --- |

## Memory Change Log

- YYYY-MM-DD: Initialized project memory.
