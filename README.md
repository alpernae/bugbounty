# Bug Bounty and Security Testing Resources

This repository is a structured workspace for bug bounty notes, Burp automation helpers, and AI-agent assets used for security research workflows.

## Repository Layout

```text
.
├── README.md
├── 0x01/
│   ├── BBTNT.md
│   └── README.md
├── 0x02/
│   └── README.md
├── 0x03/
│   ├── README.md
│   └── BamdaAction/
│       ├── CookieSwap.bambda
│       └── README.md
└── 0x04/
    ├── README.md
    ├── codex/
    │   ├── agents/
    │   ├── burp-blackbox-tester/
    │   └── security-reviewer/
    └── VSCode/
        ├── README.md
        └── gh-copilot/
            ├── agents/
            └── skills/
```

## Modules

- **0x01 - Notes and templates**
  - `BBTNT.md` is a reusable bug bounty testing note template.
- **0x02 - Tooling workspace**
  - Reserved for bug bounty tools and automation assets. The current folder contains planning documentation.
- **0x03 - Burp Bambda scripts**
  - Contains Burp Repeater Bambda actions, currently `CookieSwap.bambda`.
- **0x04 - Agent ecosystems**
  - `codex/` contains Codex agent definitions and reusable security skills.
  - `VSCode/gh-copilot/` contains GitHub Copilot custom agent and skill files.

## Getting Started

1. Clone the repository.
2. Start with the module README that matches your task.
3. Use `0x01/BBTNT.md` for engagement tracking.
4. Use `0x03/BamdaAction/` for Burp automation.
5. Use `0x04/` to customize AI-assisted security workflows.

## Contributing

Contributions are welcome. Keep docs aligned with file structure and include clear usage notes for new scripts, skills, or agent configs.

## Legal and Safety

Use these resources only in authorized environments and approved bug bounty programs.

