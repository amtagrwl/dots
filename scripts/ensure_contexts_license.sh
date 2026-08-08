#!/usr/bin/env bash
# Install the Contexts license document from 1Password without putting it in git.

set -uo pipefail

say()  { printf "  \033[1;34m→\033[0m %s\n" "$*"; }
ok()   { printf "  \033[1;32m✔\033[0m %s\n" "$*"; }
warn() { printf "  \033[1;33m⚠\033[0m %s\n" "$*"; }

[ "$(uname)" = "Darwin" ] || { say "Skipping Contexts licensing (not macOS)."; exit 0; }

license_store="$HOME/Library/Application Support/com.contextsformac.Contexts/license.contexts-license"

if [ ! -d /Applications/Contexts.app ]; then
  warn "Contexts is not installed. Run brew bundle first."
  exit 1
fi

if ! command -v op >/dev/null 2>&1; then
  warn "1Password CLI is unavailable; cannot retrieve the Contexts license."
  exit 1
fi

license_dir="$(mktemp -d "${TMPDIR:-/tmp}/contexts-license.XXXXXX")" || exit 1
license_file="$license_dir/Contexts.contexts-license"
# Called indirectly by the EXIT trap.
# shellcheck disable=SC2329
cleanup() {
  rm -f "$license_file"
  rmdir "$license_dir" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if ! op document get "Contexts License" --vault Agents --out-file "$license_file" >/dev/null; then
  warn "Could not retrieve 'Contexts License' from the Agents vault."
  exit 1
fi
chmod 600 "$license_file"

if ! plutil -lint "$license_file" >/dev/null; then
  warn "The Contexts license document in 1Password is malformed."
  exit 1
fi

if [ -s "$license_store" ] && cmp -s "$license_file" "$license_store"; then
  ok "Contexts is already licensed with the canonical 1Password document."
  exit 0
fi

say "Importing the Contexts license from 1Password…"
if ! open "$license_file"; then
  warn "Could not open the Contexts license document."
  exit 1
fi

for _ in {1..30}; do
  if [ -s "$license_store" ] && cmp -s "$license_file" "$license_store"; then
    ok "Contexts license imported."
    exit 0
  fi
  sleep 1
done

warn "Contexts did not confirm activation yet. Open Contexts → Preferences → License and retry the document."
exit 1
