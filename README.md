# Dotfiles

Global development configuration files synchronized across all devices.

## Files

- `.cursorrules` - Global Cursor AI development rules (legacy single-file format)
- `.cursor/rules/` - Cursor rules directory (modern multi-file format)
  - `always-check-skills-rules.md` - Ensures all skills and rules are evaluated on every prompt
- `.cursor/skills/` - Cursor skills directory (personal skills that apply globally)
- `update-rules.sh` - Auto-update script to sync latest rules from GitHub

## Quick Setup on New Device

```bash
# Clone and setup
git clone https://github.com/sam-osborne-tech/dotfiles.git ~/dotfiles
ln -s ~/dotfiles/.cursorrules ~/.cursorrules
chmod +x ~/dotfiles/update-rules.sh

# Test it works
ls -l ~/.cursorrules
```

## Rule Hierarchy

### Global Rules (`~/.cursor/rules/` and `~/.cursorrules`)
- Apply to ALL projects by default
- Synchronized across devices via this repository
- Contains universal development standards
- Rules with `alwaysApply: true` in frontmatter are evaluated on every prompt

**Key Rules:**
- `always-check-skills-rules.md` - Mandatory rule that ensures all skills and rules are checked before every response

### Global Skills (`~/.cursor/skills/`)
- Personal skills that apply across all projects
- Each skill is a directory with a `SKILL.md` file
- Skills are automatically discovered based on their descriptions

**Current Skills:**
- `ai-analysis-only` - Always use semantic search (`codebase_search`) instead of grep/regex
- `salesforce-internal-mcp-only` - Use internal MCP for Salesforce topics
- `valid-links-only` - Only use valid links when referencing things

### Project-Specific Rules (`./project/.cursorrules` or `./project/.cursor/rules/`)
- Created in individual project root directories
- **Extend** global rules (don't replace them)
- **Override** global rules for specific topics
- Add project-specific requirements

**Example project structure:**
```
~/code/my-salesforce-project/
├── .cursorrules          # Project-specific Salesforce rules (legacy)
├── .cursor/
│   └── rules/            # Project-specific rules (modern)
├── sfdx-project.json
└── force-app/
```

Cursor automatically merges both rule sets, with project rules taking precedence.

## Auto-Update Script

**Get latest global rules from GitHub:**
```bash
~/dotfiles/update-rules.sh
```

The script will:
- Pull latest changes from GitHub
- Check for uncommitted local changes
- Offer to commit and push if you have changes
- Verify symlink is correct
- Show you the rules location

**Run periodically (recommended):**
```bash
# Add to your shell profile (~/.zshrc or ~/.bashrc)
alias update-rules='~/dotfiles/update-rules.sh'

# Then just run:
update-rules
```

## Manual Update

**Pull latest changes:**
```bash
cd ~/dotfiles
git pull
```

**Push your changes:**
```bash
cd ~/dotfiles
# Edit .cursorrules
git add .cursorrules
git commit -m "Update cursor rules"
git push
```
