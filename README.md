# Dotfiles

Global development configuration files synchronized across all devices.

## Files

- `.cursorrules` - Global Cursor AI development rules
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

### Global Rules (`~/.cursorrules`)
- Apply to ALL projects by default
- Synchronized across devices via this repository
- Contains universal development standards

### Project-Specific Rules (`./project/.cursorrules`)
- Created in individual project root directories
- **Extend** global rules (don't replace them)
- **Override** global rules for specific topics
- Add project-specific requirements

**Example project structure:**
```
~/code/my-salesforce-project/
├── .cursorrules          # Project-specific Salesforce rules
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
