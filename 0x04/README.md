# 0x04

The `0x04` directory collects supporting resources for bug bounty workflows. It currently focuses on VS Code agent configurations that streamline code-assisted security analysis.

## Folder Structure

```
0x04/
├── README.md
└── VS-Code/
	└── Astra.agent.md
```

## Contents

- **VS-Code/Astra.agent.md**: System prompt and tool permissions for Astra, a deterministic security auditor agent that performs semantic white-box analysis (AST/CFG/DFG, symbolic execution, and strict taint tracing). It reports only confirmed vulnerabilities with locations and PoCs, avoiding speculation or mitigation advice.

## Usage

1. Open `VS-Code/Astra.agent.md` to review the agent brief and allowed capabilities.
2. Load or reference this prompt when running the Astra agent inside VS Code to drive code-centric security audits.
3. Follow the output format defined in the prompt to keep findings concise and verifiable.

---

Use these materials only for authorized security testing and bug bounty engagements.

