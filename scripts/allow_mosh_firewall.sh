#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname)" != "Darwin" ]; then
  echo "Skipping mosh firewall setup: not macOS."
  exit 0
fi

mosh_server="${IMAC_MOSH_SERVER:-/opt/homebrew/bin/mosh-server}"

if [ ! -x "$mosh_server" ]; then
  echo "mosh-server not found at $mosh_server" >&2
  echo "Install mosh first: brew install mosh" >&2
  exit 1
fi

fw=/usr/libexec/ApplicationFirewall/socketfilterfw

"$fw" --add "$mosh_server" >/dev/null 2>&1 || true
"$fw" --unblockapp "$mosh_server" >/dev/null 2>&1 || true
"$fw" --getappblocked "$mosh_server" 2>&1
