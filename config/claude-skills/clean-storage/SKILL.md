---
name: clean-storage
description: Analyze and clean up Mac storage. Use when the user mentions disk space, storage, cleanup, freeing space, "disk full", "running out of space", or similar storage concerns.
allowed-tools: Bash, Read, Glob, Grep, Agent, AskUserQuestion
---

# Mac Storage Cleanup

Analyze macOS disk usage and safely clean up space. Always scan first, report findings, then ask before deleting anything.

## Phase 1: Scan

Run the bundled scan script (single command, collects everything):

```bash
bash ~/.claude/skills/clean-storage/scan-storage.sh 2>&1
```

This outputs labeled sections (`=== DISK ===`, `=== BROWSERS ===`, etc.) covering:
disk overview, home dirs, Photos, Applications, Mail, Messages, Documents, Downloads,
Trash, Library, Application Support, Caches, Containers, browser data (Arc/Chrome/Brave/Edge/Cursor),
macOS bloat (aerials, Spotlight, Time Machine), clipboard managers (Maccy, Paste),
dev tools (Docker, Homebrew, uv, npm, bun, Codex, Claude, Terraform),
project artifacts (node_modules, .venv), and iOS backups.

If the script doesn't exist or fails, fall back to running the commands individually.

## Phase 2: Present Report

Parse the script output and present a table:

| Category | Size | Risk | Notes |
|---|---|---|---|
| ... | ... | Safe / Moderate / Caution | what happens if deleted |

Map to macOS Storage Settings categories so user can cross-reference:
- "Photos" = `~/Pictures/Photos Library.photoslibrary`
- "Applications" = `/Applications/`
- "Mail" = `~/Library/Mail/`
- "Messages" = `~/Library/Messages/`
- "Documents" = `~/Documents/` + `~/Desktop/` + container data
- "Developer" = `~/Library/Developer/`
- "Bin" = `~/.Trash/`
- "System Data" = Spotlight, Time Machine snapshots, APFS snapshots
- "iCloud Drive" = `~/Library/Mobile Documents/`

### Tiers

**Tier 1 — Safe** (caches that auto-regenerate):
Homebrew, app caches, uv/npm/bun caches, Xcode DerivedData, `__pycache__`, Docker dangling images, Trash, browser Service Worker caches, clipboard history.

**Tier 2 — Moderate** (re-downloads or rebuilds on demand):
Aerial wallpaper videos, browser IndexedDB, Docker unused images/volumes, old node_modules/.venv, Xcode Archives/DeviceSupport, AI tool caches, Terraform plugins.

**Tier 3 — Caution** (review before deleting):
Downloads, iOS backups, Mail (suggest settings change, not deletion), Photos (suggest Optimize Mac Storage), Messages, Spotlight index.

### Actionable advice for top categories

- **Photos**: iCloud "Optimize Mac Storage" (Photos > Settings > iCloud) — can free 80%+
- **Mail**: Uncheck "Download Attachments" per account, rebuild mailboxes, sort by size and delete large emails
- **Applications**: List unused apps for user to remove
- **Messages**: Set "Keep Messages" to 1 Year or 30 Days
- **System Data**: `sudo mdutil -E /` (Spotlight), `sudo tmutil deletelocalsnapshots <date>`

## Phase 3: Ask & Clean

Use AskUserQuestion to let user pick tiers/categories. Execute only approved deletions, one category at a time. Show before/after with `df -h /System/Volumes/Data`.

## Rules

- NEVER delete without asking first
- NEVER delete `~/Library/Application Support/com.apple.wallpaper/Store/` (wallpaper config)
- NEVER delete system caches in `/System/Library/` or `/Library/Caches/`
- NEVER delete `.env` files, credentials, or secrets
- ALWAYS show size to be freed before each deletion
- If Docker is not running, skip Docker cleanup
- For Downloads, list files and let user pick — never bulk delete
