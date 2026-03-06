# 0x04

The `0x04` directory collects supporting resources for bug bounty workflows. It currently focuses on agent configurations and skills that streamline code-assisted security analysis in VS Code and other environments, including custom setups for GitHub Copilot agents.

## Folder Structure

```
0x04/
├── README.md
└── VSCode/
    └── gh-copilot/
        ├── agents/
        │   ├── CoderBeast.agent.md
        │   ├── ReportAI.agent.md
        │   ├── SecurityResearcherAI.agent.md
        └── skills/
            ├── SKILL.md
            └── h1-learning.SKILL.md
```

## Contents

- **gh-copilot/agents/CoderBeast.agent.md**: Quantum cognitive coding agent for advanced automation and adversarial analysis.
- **gh-copilot/agents/ReportAI.agent.md**: Transforms security findings into structured, actionable vulnerability reports.
- **gh-copilot/agents/SecurityResearcherAI.agent.md**: Elite autonomous security researcher and blackbox web tester.
- **gh-copilot/skills/SKILL.md**: Template and reference for side skills, workflows, and methodologies.
- **gh-copilot/skills/h1-learning.SKILL.md**: Automates learning from HackerOne reports for agent knowledge improvement.

## Usage

1. Open the relevant agent or skill file in `gh-copilot/agents/` or `gh-copilot/skills/` to review its configuration and instructions.
2. Load or reference the appropriate prompt when running the agent inside your workflow (e.g., in VS Code for Copilot, or in reporting tools for ReportAI).
3. Follow the output format defined in each prompt to keep findings and reports concise and verifiable.

## GitHub Copilot Custom Agent Setup

- **Documentation**:
  - [GitHub Copilot Docs](https://docs.github.com/en/copilot)
  - [Copilot in VS Code](https://code.visualstudio.com/docs/editor/copilot)
- **Setup Steps**:
  1. Install the [GitHub Copilot extension](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) in VS Code.
  2. Authenticate with your GitHub account.
  3. Review and customize the agent and skill files in `gh-copilot/agents/` and `gh-copilot/skills/` for security-focused prompts and settings.
  4. Enable Copilot in your workspace and use the provided prompts to assist with code review, vulnerability identification, and remediation suggestions.
- **Tips**:
  - Use Copilot's inline suggestions to accelerate code analysis.
  - Combine Copilot with other agents for comprehensive security coverage.
  - Refer to the agent configuration for best practices and limitations.

---

Use these materials only for authorized security testing and bug bounty engagements.

