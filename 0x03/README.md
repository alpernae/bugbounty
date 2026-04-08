# 0x03 - Burp Bambda Scripts

This module contains Burp Suite Bambda actions used to automate repeatable bug bounty checks.

## Folder Structure

```text
0x03/
├── README.md
└── BamdaAction/
    ├── CookieSwap.bambda
    └── README.md
```

## Scripts

- `BamdaAction/CookieSwap.bambda`
  - Replaces the request `Cookie` header with a supplied session token.
  - Useful for IDOR and privilege boundary validation workflows.

## Usage

1. Open the script in Burp Repeater Bambda Actions.
2. Run it against authorized requests.
3. Compare response behavior, status codes, and redirects for access-control issues.

Use only in authorized testing environments.
