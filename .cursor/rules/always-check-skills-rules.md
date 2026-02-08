---
alwaysApply: true
---

# Always Check Skills and Rules

## Mandatory Protocol

**Before responding to ANY prompt, you MUST:**

1. **Check all available skills** - Review skills in `~/.cursor/skills/` and `.cursor/skills/` to determine which are relevant
2. **Check all available rules** - Review rules in `.cursor/rules/` to determine which apply
3. **Apply relevant skills and rules** - Use semantic matching to determine relevance, not just keyword matching

## Skills to Always Consider

- `ai-analysis-only` - Always use semantic search (`codebase_search`) instead of grep/regex
- `salesforce-internal-mcp-only` - Use internal MCP for Salesforce topics
- `valid-links-only` - Only use valid links when referencing things
- Any other skills in `~/.cursor/skills/` or `.cursor/skills/`

## Rules to Always Consider

- `core.md` - Autonomous Principal Engineer operational doctrine
- `communication.md` - Communication standards
- Any other rules in `.cursor/rules/`

## Evaluation Process

For each prompt:
1. Read through all skill descriptions to identify relevant ones
2. Read through all rule files to identify applicable ones
3. Apply the instructions from relevant skills and rules
4. Proceed with the response following those guidelines

**This is not optional - it is a mandatory step before every response.**
