#!/bin/sh
# ensure_1password_ssh.sh — point SSH at the 1Password SSH agent.
# Idempotent. Without this, git-over-SSH fails ("agent has no identities" /
# "communication with agent failed") because the keys live in 1Password.
# Requires: 1Password app installed + Settings → Developer → "Use the SSH agent" ON.

set -eu

[ "$(uname)" = "Darwin" ] || { echo "Skipping 1Password SSH config (not macOS)."; exit 0; }

ssh_dir="$HOME/.ssh"
ssh_config="$ssh_dir/config"
agent_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

mkdir -p "$ssh_dir"
chmod 700 "$ssh_dir"
touch "$ssh_config"
chmod 600 "$ssh_config"

# Guard on OUR marker, not any IdentityAgent line — the user may legitimately
# have per-host `IdentityAgent none` overrides (e.g. GitLab/VM hosts) that must
# not suppress this managed block.
marker="# 1Password SSH agent (managed by dotfiles)"
if grep -qF "$marker" "$ssh_config" 2>/dev/null; then
  echo "✔ ~/.ssh/config already has the managed 1Password SSH agent block."
else
  echo "🔧 Adding 1Password SSH agent to ~/.ssh/config..."
  # Snapshot emptiness before we open the append redirect (avoids read+write race).
  [ -s "$ssh_config" ] && leading_blank=1 || leading_blank=0
  block="$marker
Host *
  IdentityAgent \"$agent_sock\""
  [ "$leading_blank" = "1" ] && printf '\n' >> "$ssh_config"
  printf '%s\n' "$block" >> "$ssh_config"
  echo "✔ Added IdentityAgent directive."
fi

# iMac/Tailscale SSH: a dedicated agents key (2026-07-07) — NOT the 1Password
# agent. Unattended agents kept stalling on Touch ID ("agent refused
# operation") whenever the 1P agent was locked, so `ssh imac` now bypasses it
# entirely: IdentityAgent none + a plain machine-local keypair
# (~/.ssh/agents_ed25519), whose public half is tailnet-restricted in the
# iMac's authorized_keys. The private key is machine-local and never in this
# repo; on a new Mac generate one (ssh-keygen -t ed25519 -f
# ~/.ssh/agents_ed25519 -N "") and append the .pub to the iMac's
# ~/.ssh/authorized_keys (prefix: from="100.64.0.0/10").
imac_marker="# iMac Tailscale SSH (managed by dotfiles"
if grep -qF "$imac_marker" "$ssh_config" 2>/dev/null; then
  echo "✔ ~/.ssh/config already has the managed iMac SSH block."
else
  echo "🔧 Adding iMac Tailscale SSH block to ~/.ssh/config..."
  cat >> "$ssh_config" <<EOF

$imac_marker; agents key since 2026-07-07)
Host imac 100.72.234.15 imac.tailcad683.ts.net
  HostName 100.72.234.15
  User amtagrwl
  IdentityAgent none
  IdentityFile ~/.ssh/agents_ed25519
  IdentitiesOnly yes
EOF
  echo "✔ Added iMac SSH block."
fi
[ -f "$HOME/.ssh/agents_ed25519" ] || echo "⚠  ~/.ssh/agents_ed25519 missing — generate it and authorize on the iMac (see comment above)."

# AI CRM data-platform SSH (managed by dotfiles) — bastion + Postgres bronze_db on the
# internal 172.20.x network (IndiaMART VPN required to reach the bastion). Pinned to the
# machine-local crm_agent key with IdentitiesOnly so the 1Password agent does NOT spray
# keys at the bastion (which returns "Too many authentication failures"). SSH user
# amit_121480 (verified 2026-07-08 — same as the AWS IAM user, not the VPN name).
# ClickHouse 172.20.50.33 was unreachable on every port — confirm the real host with
# Shriya, then add a crm-clickhouse block mirroring crm-pg. Topology:
# ~/Workspace/Projects/AI CRM/ACCESS.md.
crm_marker="# AI CRM data-platform SSH (managed by dotfiles"
if grep -qF "$crm_marker" "$ssh_config" 2>/dev/null; then
  echo "✔ ~/.ssh/config already has the managed AI CRM SSH block."
else
  echo "🔧 Adding AI CRM data-platform SSH block to ~/.ssh/config..."
  cat >> "$ssh_config" <<EOF

$crm_marker; crm_agent key, VPN required)
Host crm-bastion
  HostName 65.0.24.32
  User amit_121480
  IdentityAgent none
  IdentityFile ~/.ssh/crm_agent
  IdentitiesOnly yes

Host crm-pg
  HostName 172.20.50.113
  User amit_121480
  IdentityAgent none
  IdentityFile ~/.ssh/crm_agent
  IdentitiesOnly yes
  ProxyJump crm-bastion
EOF
  echo "✔ Added AI CRM SSH block."
fi
[ -f "$HOME/.ssh/crm_agent" ] || echo "⚠  ~/.ssh/crm_agent missing — machine-local key (MacBook); copy/regenerate+re-authorize to use crm-* aliases."

if [ -S "$agent_sock" ]; then
  echo "✔ 1Password SSH agent socket is live."
else
  echo "⚠  1Password SSH agent socket not found at:"
  echo "     $agent_sock"
  echo "   Open 1Password → Settings → Developer → enable 'Use the SSH agent',"
  echo "   then test with: ssh -T git@github.com"
fi
