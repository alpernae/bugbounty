---
name: h1-mcp-learning
description: Guide for accessing, parsing, and learning from HackerOne reports using MCP. Use this skill to automate agent learning from valid bug bounty findings and persist knowledge in h1-learning-memory.instruction.md.
---

To learn from HackerOne reports via MCP, follow this process:

1. Use the `fetch_hackerone_reports_mcp` tool to access report URLs or provide MCP credentials for integration.
2. Use the `parse_report_content` tool to extract:
   - Title
   - Summary
   - Vulnerability type
   - Remediation steps
   - Impact
   - Reporter and date
3. Analyze each report:
   - Extract key findings and exploit techniques
   - Validate authenticity and impact
   - Identify remediation steps and patterns
   - Categorize by vulnerability type and affected asset
4. Use the `memorize_skill` tool to persist learned skills and remediation patterns in h1-learning-memory.instruction.md.
5. Feed structured insights into agent skills for:
   - Automated vulnerability detection
   - Enhanced report generation
   - Continuous learning and improvement
6. Validate agent performance by comparing new findings with historical report data.
7. Iterate and update skill with new reports and improved parsing logic.

## Decision Points
- Is the report valid and impactful?
- Are remediation steps actionable?
- Is the extracted knowledge unique or already memorized?

## Completion Checks
- All valid findings are parsed and memorized
- Remediation steps are documented
- Agent skills are updated and tested

## Example Prompts
- "Access and analyze HackerOne reports using MCP."
- "Memorize valid findings and remediation steps under h1-learning-memory.instruction.md."
- "Update agent skills with new bug bounty learnings from MCP."

## Related Customizations
- SecurityResearcherAI skill enhancement
- Automated report generation workflows
- Vulnerability pattern database

