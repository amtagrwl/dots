#!/usr/bin/env bash
# Keep Mission Control Spaces in a stable user-defined order.

set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

[ "$(uname)" = "Darwin" ] || { echo "Skipping Mission Control settings (not macOS)."; exit 0; }

printf 'Configuring Mission Control to keep Spaces in a fixed order... '
if defaults write com.apple.dock mru-spaces -bool false; then
  # Dock owns Mission Control and reloads automatically after termination.
  killall Dock >/dev/null 2>&1 || true
  if [ "$(defaults read com.apple.dock mru-spaces 2>/dev/null)" = "0" ]; then
    printf '%b✓%b Done\n' "$GREEN" "$NC"
    exit 0
  fi
fi

printf '%b✗%b Failed\n' "$RED" "$NC"
exit 1
