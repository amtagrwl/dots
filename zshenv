# Minimal zsh environment for every zsh invocation, including non-interactive SSH.
# Keep this silent and side-effect-light: mosh starts `mosh-server` through a
# non-interactive remote zsh, so Homebrew must be on PATH before ~/.zshrc runs.

if [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then
  typeset -U path PATH
  [[ -d /opt/homebrew/bin ]] && path=(/opt/homebrew/bin $path)
  [[ -d /opt/homebrew/sbin ]] && path=(/opt/homebrew/sbin $path)
  [[ -d /usr/local/bin ]] && path=(/usr/local/bin $path)
  [[ -d /usr/local/sbin ]] && path=(/usr/local/sbin $path)
  export PATH
fi

# 2026-07-09, per Amit: the 1Password service-account token is non-
# interactively available on both Macs. Agent shells (non-interactive) carry
# it so `op read` works without a fragile per-call export — agent terminal
# tools spawn a fresh shell per command, so a separate `export` step is lost
# by the next call. Interactive shells are deliberately untouched: plain
# `op` + Touch ID (personal vaults); the service account sees only the
# Agents vault.
if [[ ! -o interactive && -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" && -r "$HOME/.config/agents/op-token" ]]; then
  export OP_SERVICE_ACCOUNT_TOKEN="$(< "$HOME/.config/agents/op-token")"
fi
