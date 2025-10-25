#!/bin/bash

# Auto-update Cursor AI rules from dotfiles repository
# Run this script to sync latest rules from GitHub to your local machine

set -e

DOTFILES_DIR="$HOME/dotfiles"
RULES_FILE=".cursorrules"

echo "🔄 Updating Cursor AI rules from GitHub..."

# Navigate to dotfiles directory
cd "$DOTFILES_DIR"

# Check if we have uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  You have uncommitted changes in dotfiles:"
    git status --short
    echo ""
    read -p "Commit these changes before updating? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📝 Committing changes..."
        git add "$RULES_FILE"
        read -p "Enter commit message: " commit_msg
        git commit -m "$commit_msg"
        git push
        echo "✅ Changes pushed to GitHub"
    fi
fi

# Pull latest changes
echo "⬇️  Pulling latest rules from GitHub..."
git pull --rebase

# Verify symlink exists
if [ ! -L "$HOME/$RULES_FILE" ]; then
    echo "⚠️  Symlink missing. Creating..."
    ln -s "$DOTFILES_DIR/$RULES_FILE" "$HOME/$RULES_FILE"
fi

# Verify symlink is correct
if [ "$(readlink $HOME/$RULES_FILE)" != "$DOTFILES_DIR/$RULES_FILE" ]; then
    echo "⚠️  Symlink incorrect. Fixing..."
    rm "$HOME/$RULES_FILE"
    ln -s "$DOTFILES_DIR/$RULES_FILE" "$HOME/$RULES_FILE"
fi

echo "✅ Cursor AI rules updated successfully!"
echo "📍 Rules location: $HOME/$RULES_FILE -> $DOTFILES_DIR/$RULES_FILE"
echo ""
echo "To edit rules: vim ~/dotfiles/$RULES_FILE"
echo "To push changes: cd ~/dotfiles && git add $RULES_FILE && git commit -m 'Update rules' && git push"

