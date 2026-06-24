#!/usr/bin/env bash
set -euo pipefail

host="${1:-${IMAC_TAILSCALE_HOST:-imac}}"
session="${2:-${HERMES_TMUX_SESSION:-hermes}}"
user_prefix="${IMAC_TAILSCALE_USER:-}"
missing=0

ok() { printf '[ok] %s\n' "$*"; }
warn() { printf '[warn] %s\n' "$*" >&2; }
need() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "$1: $(command -v "$1")"
  else
    warn "$1 missing"
    missing=1
  fi
}

printf 'Checking mosh + tmux over Tailscale target=%s session=%s\n\n' "$host" "$session"

need tailscale
need mosh
need tmux

if [ "$missing" -ne 0 ]; then
  warn "Install missing tools with: brew bundle install --file ~/git/dots/Brewfile"
fi

if ! command -v tailscale >/dev/null 2>&1; then
  exit 1
fi

if ! tailscale status >/dev/null 2>&1; then
  warn "Tailscale is not running or not logged in. Open Tailscale and sign in first."
  exit 1
fi

self_ip="$(tailscale ip -4 2>/dev/null | head -n 1 || true)"
if [ -n "$self_ip" ]; then
  ok "local Tailscale IPv4: $self_ip"
fi

target_ip="$(tailscale ip -4 "$host" 2>/dev/null | head -n 1 || true)"
if [ -n "$target_ip" ]; then
  ok "target Tailscale IPv4 for $host: $target_ip"
else
  warn "Could not resolve '$host' via tailscale ip; mosh will fall back to the host string."
  target_ip="$host"
fi

netcheck_output="$(tailscale netcheck 2>&1 || true)"
udp_line="$(printf '%s\n' "$netcheck_output" | grep -E '^[[:space:]]*\* UDP:' || true)"
if printf '%s\n' "$udp_line" | grep -q 'true'; then
  ok "${udp_line#\t*}"
else
  warn "Tailscale UDP not confirmed: ${udp_line:-no UDP line from tailscale netcheck}"
fi

if ping_output="$(tailscale ping --c 1 "$host" 2>&1)"; then
  ok "tailscale ping: $(printf '%s\n' "$ping_output" | tail -n 1)"
else
  warn "tailscale ping failed: $ping_output"
fi

remote_target="$target_ip"
if [ -n "$user_prefix" ]; then
  remote_target="$user_prefix@$remote_target"
fi

if command -v ssh >/dev/null 2>&1; then
  printf '\nRemote bootstrap check over SSH (%s):\n' "$remote_target"
  if ssh -o BatchMode=yes -o ConnectTimeout=5 "$remote_target" 'command -v mosh-server && command -v tmux && tmux -V' 2>&1; then
    ok "remote has mosh-server + tmux"
  else
    warn "remote SSH bootstrap check failed/skipped. If normal ssh works interactively, this is usually just key auth/BatchMode."
  fi
fi

cat <<EOF

Connect command:
  mosh $remote_target -- tmux new-session -A -s $session

Shell shortcut after dotfiles install/source:
  himac

If Ghostty ever gets stuck in mouse-reporting mode:
  fixterm
EOF
