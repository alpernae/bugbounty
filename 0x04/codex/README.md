# 0x04/codex - Codex Agents and Skills

This folder contains Codex-specific agent definitions and reusable security skill packs.

## Folder Structure

```text
0x04/codex/
├── README.md
├── agents/
│   ├── burp-blackbox-coordinator.toml
│   ├── burp-exploit-validator.toml
│   ├── burp-logic-race-tester.toml
│   ├── burp-surface-mapper.toml
│   ├── security-exploit-researcher.toml
│   ├── security-llm-researcher.toml
│   ├── security-report-synthesizer.toml
│   ├── security-research-coordinator.toml
│   └── security-surface-mapper.toml
├── burp-blackbox-tester/
│   ├── SKILL.md
│   ├── agents/openai.yaml
│   ├── assets/
│   ├── references/
│   └── scripts/
└── security-reviewer/
    ├── SKILL.md
    ├── .github/memory.md
    ├── agents/openai.yaml
    ├── assets/
    ├── references/
    └── scripts/
```

## Components

- [agents](agents/)
  - Standalone coordinator and specialist agent profiles in `.toml` format.
- [burp-blackbox-tester](burp-blackbox-tester/)
  - Burp MCP black-box testing skill pack with workflow docs, vuln-class references, and memory bootstrap scripts.
- [security-reviewer](security-reviewer/)
  - Source-code security review skill pack focused on exploitability-first analysis and reporting.

## Quick Start

1. Pick the workflow you want:
   - [burp-blackbox-tester/SKILL.md](burp-blackbox-tester/SKILL.md)
   - [security-reviewer/SKILL.md](security-reviewer/SKILL.md)
2. Review corresponding metadata:
   - [burp-blackbox-tester/agents/openai.yaml](burp-blackbox-tester/agents/openai.yaml)
   - [security-reviewer/agents/openai.yaml](security-reviewer/agents/openai.yaml)
3. Initialize project memory when needed:
   - [burp-blackbox-tester/scripts/ensure-project-memory.ps1](burp-blackbox-tester/scripts/ensure-project-memory.ps1)
   - [security-reviewer/scripts/ensure-project-memory.ps1](security-reviewer/scripts/ensure-project-memory.ps1)
4. Use the `references/` content for category-specific testing and reporting guidance.

## Notes

- Respect scope constraints from `.github/SCOPE.md` when present in the target project.
- Use these assets only in authorized security testing environments.