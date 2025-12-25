# 0x04

The `0x04` directory collects supporting resources for bug bounty workflows. It currently focuses on agent configurations that streamline code-assisted security analysis in VS Code and other environments, including custom setups for GitHub Copilot agents.

## Folder Structure

```
0x04/
├── README.md
├── VS-Code/
│   └── Astra.agent.md
├── ReportAI/
│   └── ReportAI.agent.md
└── Copilot/
	└── Copilot.agent.md
```

## Contents

- **VS-Code/Astra.agent.md**: System prompt and tool permissions for Astra, a deterministic security auditor agent that performs semantic white-box analysis (AST/CFG/DFG, symbolic execution, and strict taint tracing). It reports only confirmed vulnerabilities with locations and PoCs, avoiding speculation or mitigation advice.
- **ReportAI/ReportAI.agent.md**: System prompt and configuration for ReportAI, an agent designed to automate the generation of structured vulnerability reports based on audit findings. It formats outputs for bug bounty submissions and ensures clarity, reproducibility, and compliance with disclosure guidelines.
- **Copilot/Copilot.agent.md**: Custom configuration and prompt for integrating GitHub Copilot as a security analysis assistant. Includes setup instructions, recommended extensions, and usage tips for leveraging Copilot in bug bounty workflows.

## Usage

1. Open the relevant agent file (`VS-Code/Astra.agent.md`, `ReportAI/ReportAI.agent.md`, or `Copilot/Copilot.agent.md`) to review the agent brief and allowed capabilities.
2. Load or reference the appropriate prompt when running the agent inside your workflow (e.g., in VS Code for Astra or Copilot, or in reporting tools for ReportAI).
3. Follow the output format defined in each prompt to keep findings and reports concise and verifiable.

## GitHub Copilot Custom Agent Setup

- **Documentation**:  
  - [GitHub Copilot Docs](https://docs.github.com/en/copilot)  
  - [Copilot in VS Code](https://code.visualstudio.com/docs/editor/copilot)
- **Setup Steps**:
  1. Install the [GitHub Copilot extension](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) in VS Code.
  2. Authenticate with your GitHub account.
  3. Review and customize the `Copilot/Copilot.agent.md` file for security-focused prompts and settings.
  4. Enable Copilot in your workspace and use the provided prompts to assist with code review, vulnerability identification, and remediation suggestions.
- **Tips**:
  - Use Copilot's inline suggestions to accelerate code analysis.
  - Combine Copilot with other agents for comprehensive security coverage.
  - Refer to the agent configuration for best practices and limitations.

---

Use these materials only for authorized security testing and bug bounty engagements.

