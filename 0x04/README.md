# 0x04 - AI Agents and Security Skills

This module contains AI-agent assets for two ecosystems:

- `codex/` for Codex agent and skill packs
- `VSCode/gh-copilot/` for GitHub Copilot custom agents and skills

## Folder Structure

```text
0x04/
├── README.md
├── codex/
│   ├── README.md
│   ├── agents/
│   │   ├── burp-blackbox-coordinator.toml
│   │   ├── burp-exploit-validator.toml
│   │   ├── burp-logic-race-tester.toml
│   │   ├── burp-surface-mapper.toml
│   │   ├── security-exploit-researcher.toml
│   │   ├── security-llm-researcher.toml
│   │   ├── security-report-synthesizer.toml
│   │   ├── security-research-coordinator.toml
│   │   └── security-surface-mapper.toml
│   ├── burp-blackbox-tester/
│   │   ├── SKILL.md
│   │   ├── agents/openai.yaml
│   │   ├── assets/burp-blackbox-tester-icon.svg
│   │   ├── references/
│   │   └── scripts/
│   └── security-reviewer/
│       ├── SKILL.md
│       ├── .github/memory.md
│       ├── agents/openai.yaml
│       ├── assets/security-reviewer-icon.svg
│       ├── references/
│       └── scripts/
└── VSCode/
    ├── README.md
    └── gh-copilot/
        ├── agents/
        └── skills/
```

## Highlights

- `codex/README.md`: entry guide for Codex agents and skill packs in this folder.
- `codex/agents/`: role-specific coordinator, mapper, validator, and reporting agent definitions.
- `codex/burp-blackbox-tester/`: Burp-focused skill with references, templates, scripts, and metadata.
- `codex/security-reviewer/`: code-review-focused security skill package with report templates and memory bootstrap scripts.
- `VSCode/gh-copilot/agents/`: Copilot agent personas for coding, reporting, and source-code security analysis.
- `VSCode/gh-copilot/skills/`: reusable Copilot skill prompts, including HackerOne learning support.

## Usage

1. Pick the platform (`codex` or `VSCode/gh-copilot`).
2. Open the relevant `SKILL.md` or agent file.
3. Keep project memory/context files aligned with your current target.
4. Use only for authorized security testing and review.

