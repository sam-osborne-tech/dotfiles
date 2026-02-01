#!/bin/bash
# Git Bundle Sync - Transfer repos across air-gapped/restricted networks
# Usage: ./git-bundle-sync.sh [command]

set -e

BUNDLE_DIR="${BUNDLE_DIR:-$(pwd)}"
PROJECT_NAME=$(basename $(git rev-parse --show-toplevel))
DATE=$(date +%Y%m%d-%H%M)

show_help() {
    echo "Git Bundle Sync - Transfer repos across restricted networks"
    echo ""
    echo "Usage: ./git-bundle-sync.sh [command]"
    echo ""
    echo "Commands:"
    echo "  full        Create full bundle (entire repo history)"
    echo "  out         Bundle outbound changes (since last-sync-out tag)"
    echo "  in FILE     Import inbound bundle and merge"
    echo "  status      Show sync status and pending changes"
    echo "  help        Show this help"
    echo ""
    echo "Environment:"
    echo "  BUNDLE_DIR  Directory for bundles (default: current dir)"
}

bundle_full() {
    BUNDLE_FILE="${BUNDLE_DIR}/${PROJECT_NAME}-full-${DATE}.bundle"
    echo "Creating full bundle..."
    git bundle create "$BUNDLE_FILE" --all
    git bundle verify "$BUNDLE_FILE"
    echo ""
    echo "✓ Created: $BUNDLE_FILE"
    ls -lh "$BUNDLE_FILE"
}

bundle_out() {
    # Check if last-sync-out tag exists
    if git rev-parse last-sync-out >/dev/null 2>&1; then
        BASE="last-sync-out"
        COMMITS=$(git rev-list ${BASE}..HEAD --count)
        
        if [ "$COMMITS" -eq 0 ]; then
            echo "No new commits since last sync"
            exit 0
        fi
        
        echo "Bundling $COMMITS commits since last sync..."
        BUNDLE_FILE="${BUNDLE_DIR}/${PROJECT_NAME}-out-${DATE}.bundle"
        git bundle create "$BUNDLE_FILE" ${BASE}..HEAD
    else
        echo "No previous sync tag found. Creating full bundle..."
        bundle_full
        BUNDLE_FILE="${BUNDLE_DIR}/${PROJECT_NAME}-full-${DATE}.bundle"
    fi
    
    # Update sync tag
    git tag -f last-sync-out HEAD
    
    git bundle verify "$BUNDLE_FILE"
    echo ""
    echo "✓ Created: $BUNDLE_FILE"
    echo "✓ Tagged HEAD as last-sync-out"
    ls -lh "$BUNDLE_FILE"
}

bundle_in() {
    BUNDLE_FILE="$1"
    
    if [ -z "$BUNDLE_FILE" ]; then
        echo "Error: No bundle file specified"
        echo "Usage: ./git-bundle-sync.sh in <bundle-file>"
        exit 1
    fi
    
    if [ ! -f "$BUNDLE_FILE" ]; then
        echo "Error: Bundle file not found: $BUNDLE_FILE"
        exit 1
    fi
    
    echo "Verifying bundle..."
    git bundle verify "$BUNDLE_FILE"
    
    echo ""
    echo "Fetching from bundle..."
    git fetch "$BUNDLE_FILE" main:incoming
    
    echo ""
    echo "Commits to merge:"
    git log --oneline HEAD..incoming | head -20
    
    echo ""
    read -p "Merge these commits? [y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git merge incoming -m "Merge from bundle: $(basename $BUNDLE_FILE)"
        git branch -d incoming
        git tag -f last-sync-in HEAD
        echo "✓ Merged and tagged as last-sync-in"
    else
        git branch -d incoming
        echo "Merge cancelled"
    fi
}

show_status() {
    echo "=== Git Bundle Sync Status ==="
    echo ""
    echo "Project: $PROJECT_NAME"
    echo "Current branch: $(git branch --show-current)"
    echo "Current commit: $(git rev-parse --short HEAD)"
    echo ""
    
    if git rev-parse last-sync-out >/dev/null 2>&1; then
        OUT_COMMITS=$(git rev-list last-sync-out..HEAD --count)
        echo "Last outbound sync: $(git log -1 --format='%h %s' last-sync-out)"
        echo "Commits pending out: $OUT_COMMITS"
    else
        echo "Last outbound sync: never"
    fi
    
    echo ""
    
    if git rev-parse last-sync-in >/dev/null 2>&1; then
        echo "Last inbound sync: $(git log -1 --format='%h %s' last-sync-in)"
    else
        echo "Last inbound sync: never"
    fi
    
    echo ""
    echo "=== Recent bundles in $BUNDLE_DIR ==="
    ls -lht "$BUNDLE_DIR"/*.bundle 2>/dev/null | head -5 || echo "No bundles found"
}

# Main
case "${1:-help}" in
    full)
        bundle_full
        ;;
    out)
        bundle_out
        ;;
    in)
        bundle_in "$2"
        ;;
    status)
        show_status
        ;;
    help|*)
        show_help
        ;;
esac
