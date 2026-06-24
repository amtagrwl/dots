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
