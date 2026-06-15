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

if [ -S "$agent_sock" ]; then
  echo "✔ 1Password SSH agent socket is live."
else
  echo "⚠  1Password SSH agent socket not found at:"
  echo "     $agent_sock"
  echo "   Open 1Password → Settings → Developer → enable 'Use the SSH agent',"
  echo "   then test with: ssh -T git@github.com"
fi
