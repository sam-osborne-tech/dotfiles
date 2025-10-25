# Dotfiles

Global development configuration files synchronized across all devices.

## Files

- `.cursorrules` - Global Cursor AI development rules

## Setup on New Device

```bash
git clone https://github.com/sam-osborne-tech/dotfiles.git ~/dotfiles
ln -s ~/dotfiles/.cursorrules ~/.cursorrules
```

## Update Rules

```bash
cd ~/dotfiles
# Edit .cursorrules
git add .cursorrules
git commit -m "Update cursor rules"
git push
```

## Sync Changes

```bash
cd ~/dotfiles
git pull
```
