#!/usr/bin/env bash
# scan-storage.sh — Collects macOS storage data in one pass.
# Output: structured text blocks that Claude can parse in a single read.
set -euo pipefail

H="$HOME"
SEP="=== %s ===\n"

# ── Disk overview ──
printf "$SEP" "DISK"
df -h /System/Volumes/Data

# ── Top-level home ──
printf "\n$SEP" "HOME"
du -d1 -h "/System/Volumes/Data$H/" 2>/dev/null | sort -hr | head -20

# ── Photos ──
printf "\n$SEP" "PHOTOS"
du -sh "$H/Pictures/Photos Library.photoslibrary" 2>/dev/null || echo "No Photos library"

# ── Applications ──
printf "\n$SEP" "APPLICATIONS"
du -sh /Applications/*/ 2>/dev/null | sort -hr | head -20

# ── Mail ──
printf "\n$SEP" "MAIL"
du -d1 -h "$H/Library/Mail/" 2>/dev/null | sort -hr | head -10

# ── Messages ──
printf "\n$SEP" "MESSAGES"
du -sh "$H/Library/Messages/" 2>/dev/null || echo "0B"

# ── Documents / Desktop / iCloud ──
printf "\n$SEP" "DOCUMENTS"
du -sh "$H/Documents/" 2>/dev/null || echo "Documents: 0B"
du -sh "$H/Desktop/" 2>/dev/null || echo "Desktop: 0B"
du -sh "$H/Library/Mobile Documents/" 2>/dev/null || echo "iCloud: 0B"

# ── Downloads ──
printf "\n$SEP" "DOWNLOADS"
du -sh "$H/Downloads/" 2>/dev/null
ls -lhS "$H/Downloads/" 2>/dev/null | head -15

# ── Trash ──
printf "\n$SEP" "TRASH"
du -sh "$H/.Trash/" 2>/dev/null || echo "0B"

# ── Library breakdown ──
printf "\n$SEP" "LIBRARY"
du -d1 -h "/System/Volumes/Data$H/Library/" 2>/dev/null | sort -hr | head -15

# ── Application Support ──
printf "\n$SEP" "APP_SUPPORT"
find "$H/Library/Application Support" -maxdepth 1 -type d -exec du -sh {} \; 2>/dev/null | sort -hr | head -20

# ── Caches ──
printf "\n$SEP" "CACHES"
du -sh "$H/Library/Caches/"*/ 2>/dev/null | sort -hr | head -15

# ── Containers + Group Containers ──
printf "\n$SEP" "CONTAINERS"
du -d1 -h "$H/Library/Containers/" 2>/dev/null | sort -hr | head -10
echo "---"
du -d1 -h "$H/Library/Group Containers/" 2>/dev/null | sort -hr | head -10

# ── Browser data (Chromium Service Workers + IndexedDB are the big offenders) ──
printf "\n$SEP" "BROWSERS"
for browser_dir in \
  "$H/Library/Application Support/Arc/User Data/Default" \
  "$H/Library/Application Support/Google/Chrome/Default" \
  "$H/Library/Application Support/BraveSoftware/Brave-Browser/Default" \
  "$H/Library/Application Support/Microsoft Edge/Default" \
  "$H/Library/Application Support/Cursor/User"; do
  if [ -d "$browser_dir" ]; then
    echo ">> $(basename "$(dirname "$(dirname "$browser_dir")")")"
    du -d1 -h "$browser_dir/" 2>/dev/null | sort -hr | head -8
    echo ""
  fi
done

# ── macOS bloat ──
printf "\n$SEP" "MACOS_BLOAT"
echo "Aerial videos:"
du -sh "$H/Library/Application Support/com.apple.wallpaper/aerials/videos" 2>/dev/null || echo "0B"
echo "Spotlight index:"
du -sh "$H/Library/Metadata/CoreSpotlight" 2>/dev/null || echo "0B"
echo "Time Machine snapshots:"
tmutil listlocalsnapshots / 2>/dev/null | head -5 || echo "none"

# ── Clipboard managers (Maccy, Paste, CopyClip) ──
printf "\n$SEP" "CLIPBOARD_MANAGERS"
find "$H/Library" -maxdepth 3 \( -iname "*maccy*" -o -iname "*copyclip*" \) -exec du -sh {} \; 2>/dev/null | sort -hr | head -5
du -sh "$H/Library/Containers/com.p0deje.Maccy" 2>/dev/null || true
echo "(done)"

# ── Developer tools ──
printf "\n$SEP" "DEV_TOOLS"
echo "Xcode DerivedData:"; du -sh "$H/Library/Developer/Xcode/DerivedData" 2>/dev/null || echo "0B"
echo "Xcode Archives:";    du -sh "$H/Library/Developer/Xcode/Archives" 2>/dev/null || echo "0B"
echo "Xcode DeviceSupport:"; du -sh "$H/Library/Developer/Xcode/iOS DeviceSupport" 2>/dev/null || echo "0B"
echo "Docker:";             docker system df 2>/dev/null || echo "not running"
echo "Homebrew cache:";     du -sh "$H/Library/Caches/Homebrew" 2>/dev/null || echo "0B"
echo "uv cache:";           du -sh "$H/.cache/uv" 2>/dev/null || echo "0B"
echo "npm cache:";          du -sh "$H/.npm" 2>/dev/null || echo "0B"
echo "bun cache:";          du -sh "$H/.bun" 2>/dev/null || echo "0B"
echo "Codex:";              du -sh "$H/.codex" 2>/dev/null || echo "0B"
echo "Claude:";             du -sh "$H/.claude" 2>/dev/null || echo "0B"
echo "Terraform/Tofu:";     du -sh "$H/.terraform.d" 2>/dev/null || echo "0B"

# ── Project artifacts ──
printf "\n$SEP" "PROJECT_ARTIFACTS"
echo "node_modules:"
find "$H/git" -name node_modules -type d -maxdepth 4 -exec du -sh {} \; 2>/dev/null | sort -hr | head -10
echo "Python .venv:"
find "$H/git" -name .venv -type d -maxdepth 4 -exec du -sh {} \; 2>/dev/null | sort -hr | head -10

# ── iOS backups ──
printf "\n$SEP" "IOS_BACKUPS"
du -sh "$H/Library/Application Support/MobileSync/Backup" 2>/dev/null || echo "none"

printf "\n$SEP" "DONE"
