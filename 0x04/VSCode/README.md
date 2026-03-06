# 0x04 VSCode Copilot Agents

The `0x04/VSCode` directory contains resources for integrating AI-powered agents and skills into your bug bounty workflow using Visual Studio Code (VS Code) Copilot.

## Folder Structure

```
0x04/
├── README.md
└── VSCode/
    ├── gh-copilot/
    │   ├── agents/
    │   │   ├── CoderBeast.agent.md
    │   │   ├── ReportAI.agent.md
    │   │   ├── SecurityResearcherAI.agent.md
    │   └── skills/
    │       ├── SKILL.md
    │       └── h1-learning.SKILL.md
    └── README.md
```

## Copilot Custom Agents

The following agents are available in `gh-copilot/agents/`:

- **CoderBeast.agent.md**: Quantum cognitive coding agent for advanced automation and adversarial analysis.
- **ReportAI.agent.md**: Transforms security findings into structured, actionable vulnerability reports.
- **SecurityResearcherAI.agent.md**: Elite autonomous security researcher and blackbox web tester.

## Copilot Skills

The following skills are available in `gh-copilot/skills/`:

- **SKILL.md**: Template and reference for side skills, workflows, and methodologies.
- **h1-learning.SKILL.md**: Automates learning from HackerOne reports for agent knowledge improvement.

## Usage

1. Open the relevant agent or skill file in `gh-copilot/agents/` or `gh-copilot/skills/` to review its configuration and instructions.
2. Load or reference the appropriate prompt when running the agent inside your workflow (e.g., in VS Code for Copilot, or in reporting tools for ReportAI).
3. Follow the output format defined in each prompt to keep findings and reports concise and verifiable.
