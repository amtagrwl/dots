#!/usr/bin/env bash
# Make the normal macOS screenshot shortcuts copy captures to the clipboard.

set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

[ "$(uname)" = "Darwin" ] || { echo "Skipping screenshot settings (not macOS)."; exit 0; }

printf 'Configuring macOS screenshots to use the clipboard... '
if defaults write com.apple.screencapture target -string clipboard; then
  # SystemUIServer owns the keyboard-shortcut capture service and reloads automatically.
  killall SystemUIServer >/dev/null 2>&1 || true
  if [ "$(defaults read com.apple.screencapture target 2>/dev/null)" = "clipboard" ]; then
    printf '%b✓%b Done\n' "$GREEN" "$NC"
    exit 0
  fi
fi

printf '%b✗%b Failed\n' "$RED" "$NC"
exit 1
