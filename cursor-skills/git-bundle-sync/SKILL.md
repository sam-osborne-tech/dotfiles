---
name: git-bundle-sync
description: Transfer git repositories across air-gapped or restricted networks using git bundles. Use when the user needs to sync repos between machines without network access, mentions restricted networks, air-gapped environments, or asks about transferring code without git push/pull.
---

# Git Bundle Sync

Sync git repos across restricted/air-gapped networks using portable bundle files.

## When to Use

- Transferring repos to/from secure corporate networks
- Syncing between machines without shared network access
- USB/email-based code transfer
- Air-gapped development environments

## Quick Reference

| Command | Purpose |
|---------|---------|
| `git bundle create name.bundle --all` | Full repo bundle |
| `git bundle create name.bundle base..HEAD` | Incremental bundle |
| `git clone repo.bundle project-dir` | Clone from bundle |
| `git fetch repo.bundle main:incoming` | Fetch updates |
| `git bundle verify repo.bundle` | Verify bundle integrity |

## Full Repo Transfer

**Create bundle (source machine):**
```bash
git bundle create project.bundle --all
# Transfers via USB, email, SharePoint, etc.
```

**Clone from bundle (destination machine):**
```bash
git clone project.bundle project-name
cd project-name
git remote set-url origin <real-remote-url>  # Optional
```

## Incremental Sync (Bidirectional)

**Setup - tag last sync point:**
```bash
git tag last-sync HEAD
```

**Outbound (your changes → other machine):**
```bash
# Create bundle with new commits only
git bundle create outbound.bundle last-sync..HEAD

# After transfer, on other machine:
git fetch ../outbound.bundle main:incoming
git merge incoming
git branch -d incoming
git tag -f last-sync HEAD
```

**Inbound (other machine's changes → yours):**
```bash
# Receive bundle, then:
git fetch ../inbound.bundle main:incoming
git merge incoming
git branch -d incoming
git tag -f last-sync HEAD
```

## Helper Scripts

**Single repo** - `scripts/git-bundle-sync.sh`:
```bash
./scripts/git-bundle-sync.sh full      # Full bundle
./scripts/git-bundle-sync.sh out       # Outbound changes
./scripts/git-bundle-sync.sh in FILE   # Import bundle
./scripts/git-bundle-sync.sh status    # Show sync status
```

**Multi-repo + Disguised** - `scripts/sync-manager.sh`:
```bash
sync-manager.sh init              # Create config
sync-manager.sh add /path/to/repo # Add repo to list
sync-manager.sh list              # Show repos
sync-manager.sh pack              # Bundle all (disguised names)
sync-manager.sh unpack /path/     # Import bundles
sync-manager.sh status            # Status all repos
```

Disguised output goes to `~/Documents/Backups/` with names like:
- `backup_a1b2c3d4_20260128.bak`
- `data_e5f6g7h8_20260128.old`
- `cache_i9j0k1l2_20260128.tmp`

Config stored at `~/.sync-repos.conf`

## Size Considerations

| Method | Typical Size | Best For |
|--------|--------------|----------|
| Full bundle | ~10-50MB | Initial transfer |
| Incremental | ~1-5MB | Regular syncs |
| Deliverables zip | Varies | Non-git users |

Check size before transfer:
```bash
du -sh .                    # Full project
git bundle create /tmp/test.bundle --all && ls -lh /tmp/test.bundle
```

## Troubleshooting

**"prerequisite not met"**: Bundle is incremental but base commits missing. Use full bundle instead.

**Merge conflicts**: Resolve normally with `git mergetool` or manual edit, then commit.

**Verify bundle is valid:**
```bash
git bundle verify file.bundle
```
