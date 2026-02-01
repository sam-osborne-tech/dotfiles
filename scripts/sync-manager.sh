#!/bin/bash
# Sync Manager - Inconspicuous multi-repo bundle transfer
# Bundles look like backup/log files, handles multiple repos

set -e

CONFIG_FILE="${HOME}/.sync-repos.conf"
SYNC_DIR="${HOME}/Documents/Backups"
DATE=$(date +%Y%m%d)

# Inconspicuous file naming
EXTENSIONS=("bak" "dat" "log" "tmp" "old")
PREFIXES=("backup" "cache" "temp" "log" "data")

show_help() {
    echo "Sync Manager - Multi-repo inconspicuous transfer"
    echo ""
    echo "Usage: sync-manager.sh [command]"
    echo ""
    echo "Commands:"
    echo "  init              Create config file with repo list"
    echo "  add PATH [NAME]   Add repo to sync list"
    echo "  list              Show configured repos"
    echo "  pack              Bundle all repos (outbound)"
    echo "  unpack DIR        Import bundles from directory"
    echo "  status            Show sync status for all repos"
    echo ""
    echo "Config: $CONFIG_FILE"
    echo "Output: $SYNC_DIR"
}

init_config() {
    mkdir -p "$SYNC_DIR"
    
    if [ -f "$CONFIG_FILE" ]; then
        echo "Config exists: $CONFIG_FILE"
        cat "$CONFIG_FILE"
        return
    fi
    
    cat > "$CONFIG_FILE" << 'EOF'
# Sync Manager Config
# Format: name|path
# Example: myproject|/Users/me/code/myproject

EOF
    echo "Created: $CONFIG_FILE"
    echo "Add repos with: sync-manager.sh add /path/to/repo"
}

add_repo() {
    local REPO_PATH="$1"
    local REPO_NAME="$2"
    
    if [ -z "$REPO_PATH" ]; then
        echo "Usage: sync-manager.sh add /path/to/repo [name]"
        exit 1
    fi
    
    # Resolve to absolute path
    REPO_PATH=$(cd "$REPO_PATH" && pwd)
    
    # Verify it's a git repo
    if [ ! -d "$REPO_PATH/.git" ]; then
        echo "Error: Not a git repo: $REPO_PATH"
        exit 1
    fi
    
    # Default name from directory
    if [ -z "$REPO_NAME" ]; then
        REPO_NAME=$(basename "$REPO_PATH")
    fi
    
    # Check if already exists
    if grep -q "|${REPO_PATH}$" "$CONFIG_FILE" 2>/dev/null; then
        echo "Already configured: $REPO_NAME"
        return
    fi
    
    echo "${REPO_NAME}|${REPO_PATH}" >> "$CONFIG_FILE"
    echo "Added: $REPO_NAME -> $REPO_PATH"
}

list_repos() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "No config. Run: sync-manager.sh init"
        exit 1
    fi
    
    echo "Configured repos:"
    echo ""
    grep -v "^#" "$CONFIG_FILE" | grep -v "^$" | while IFS='|' read -r name path; do
        if [ -d "$path" ]; then
            echo "  ✓ $name -> $path"
        else
            echo "  ✗ $name -> $path (not found)"
        fi
    done
}

get_disguised_name() {
    local REAL_NAME="$1"
    local IDX=$((RANDOM % ${#PREFIXES[@]}))
    local PREFIX="${PREFIXES[$IDX]}"
    local EXT="${EXTENSIONS[$IDX]}"
    
    # Hash the name for consistency but looks random
    local HASH=$(echo "$REAL_NAME" | md5sum | cut -c1-8)
    
    echo "${PREFIX}_${HASH}_${DATE}.${EXT}"
}

pack_all() {
    mkdir -p "$SYNC_DIR"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "No config. Run: sync-manager.sh init"
        exit 1
    fi
    
    echo "Packing repos to: $SYNC_DIR"
    echo ""
    
    # Create manifest (also disguised)
    MANIFEST_FILE="$SYNC_DIR/.manifest"
    echo "# Manifest $DATE" > "$MANIFEST_FILE"
    
    grep -v "^#" "$CONFIG_FILE" | grep -v "^$" | while IFS='|' read -r name path; do
        if [ ! -d "$path" ]; then
            echo "  ✗ $name - not found, skipping"
            continue
        fi
        
        cd "$path"
        
        # Get disguised filename
        BUNDLE_NAME=$(get_disguised_name "$name")
        BUNDLE_PATH="$SYNC_DIR/$BUNDLE_NAME"
        
        # Check for incremental vs full
        if git rev-parse last-sync-out >/dev/null 2>&1; then
            COMMITS=$(git rev-list last-sync-out..HEAD --count)
            if [ "$COMMITS" -eq 0 ]; then
                echo "  - $name: no changes"
                continue
            fi
            git bundle create "$BUNDLE_PATH" last-sync-out..HEAD 2>/dev/null
            TYPE="incremental"
        else
            git bundle create "$BUNDLE_PATH" --all 2>/dev/null
            TYPE="full"
        fi
        
        # Update sync tag
        git tag -f last-sync-out HEAD >/dev/null 2>&1
        
        # Record in manifest
        echo "${BUNDLE_NAME}|${name}|${TYPE}" >> "$MANIFEST_FILE"
        
        SIZE=$(ls -lh "$BUNDLE_PATH" | awk '{print $5}')
        echo "  ✓ $name -> $BUNDLE_NAME ($SIZE, $TYPE)"
    done
    
    echo ""
    echo "Output directory: $SYNC_DIR"
    ls -la "$SYNC_DIR"
}

unpack_all() {
    local SOURCE_DIR="$1"
    
    if [ -z "$SOURCE_DIR" ]; then
        echo "Usage: sync-manager.sh unpack /path/to/bundles"
        exit 1
    fi
    
    MANIFEST_FILE="$SOURCE_DIR/.manifest"
    
    if [ ! -f "$MANIFEST_FILE" ]; then
        echo "No manifest found in $SOURCE_DIR"
        echo "Looking for bundle files..."
        ls -la "$SOURCE_DIR"/*.{bak,dat,log,tmp,old} 2>/dev/null || echo "No bundles found"
        exit 1
    fi
    
    echo "Unpacking from: $SOURCE_DIR"
    echo ""
    
    grep -v "^#" "$MANIFEST_FILE" | while IFS='|' read -r bundle_name repo_name bundle_type; do
        BUNDLE_PATH="$SOURCE_DIR/$bundle_name"
        
        if [ ! -f "$BUNDLE_PATH" ]; then
            echo "  ✗ $repo_name: bundle not found"
            continue
        fi
        
        # Find repo path from config
        REPO_PATH=$(grep "^${repo_name}|" "$CONFIG_FILE" | cut -d'|' -f2)
        
        if [ -z "$REPO_PATH" ]; then
            echo "  ? $repo_name: not in config, skipping"
            echo "    Add with: sync-manager.sh add /path/to/repo $repo_name"
            continue
        fi
        
        if [ ! -d "$REPO_PATH" ]; then
            echo "  ! $repo_name: repo not found at $REPO_PATH"
            echo "    Clone with: git clone $BUNDLE_PATH $REPO_PATH"
            continue
        fi
        
        cd "$REPO_PATH"
        
        # Verify bundle
        if ! git bundle verify "$BUNDLE_PATH" >/dev/null 2>&1; then
            echo "  ✗ $repo_name: invalid bundle"
            continue
        fi
        
        # Fetch and merge
        git fetch "$BUNDLE_PATH" main:incoming 2>/dev/null || git fetch "$BUNDLE_PATH" master:incoming 2>/dev/null
        
        INCOMING_COMMITS=$(git rev-list HEAD..incoming --count 2>/dev/null || echo "0")
        
        if [ "$INCOMING_COMMITS" -eq 0 ]; then
            echo "  - $repo_name: already up to date"
            git branch -D incoming 2>/dev/null || true
            continue
        fi
        
        git merge incoming -m "Sync from bundle" --no-edit 2>/dev/null
        git branch -D incoming 2>/dev/null
        git tag -f last-sync-in HEAD >/dev/null 2>&1
        
        echo "  ✓ $repo_name: merged $INCOMING_COMMITS commits"
    done
}

show_status() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "No config. Run: sync-manager.sh init"
        exit 1
    fi
    
    echo "=== Sync Status ==="
    echo ""
    
    grep -v "^#" "$CONFIG_FILE" | grep -v "^$" | while IFS='|' read -r name path; do
        if [ ! -d "$path" ]; then
            echo "$name: NOT FOUND"
            continue
        fi
        
        cd "$path"
        
        echo "$name:"
        echo "  Path: $path"
        echo "  Branch: $(git branch --show-current)"
        
        if git rev-parse last-sync-out >/dev/null 2>&1; then
            OUT=$(git rev-list last-sync-out..HEAD --count)
            echo "  Pending out: $OUT commits"
        else
            echo "  Pending out: never synced"
        fi
        
        if git rev-parse last-sync-in >/dev/null 2>&1; then
            echo "  Last in: $(git log -1 --format='%h %s' last-sync-in)"
        fi
        echo ""
    done
}

# Main
case "${1:-help}" in
    init)
        init_config
        ;;
    add)
        add_repo "$2" "$3"
        ;;
    list)
        list_repos
        ;;
    pack)
        pack_all
        ;;
    unpack)
        unpack_all "$2"
        ;;
    status)
        show_status
        ;;
    help|*)
        show_help
        ;;
esac
