# 0x03

The `0x03` directory contains Burp Suite Bambda action scripts to automate and streamline common bug bounty tasks. These actions help accelerate testing workflows while keeping evidence and behavior consistent.

## Folder Structure

```
0x03/
├── README.md
└── BamdaAction/
    ├── CookieSwap.bambda
    └── README.md
```

## Contents

- **BamdaAction/**: Collection of Bambda action scripts for Burp Suite Repeater automation.
  - **CookieSwap.bambda**: Rewrites the `Cookie` header with another session token to test IDOR/privilege escalation scenarios, logging responses and redirects.

## Usage

1. Open the desired `.bambda` script in Burp Suite Repeater.
2. Apply the action to the relevant request to automate header manipulation or other scripted behavior.
3. Review logs/output to validate responses and potential issues.

Use these scripts only in authorized environments and programs.
