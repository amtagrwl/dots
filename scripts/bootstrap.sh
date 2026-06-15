#!/usr/bin/env bash
# bootstrap.sh — fresh-Mac prerequisites that `./install` assumes but does not do.
# Safe to re-run (idempotent). Run this BEFORE `./install` on a brand-new machine:
#
#   xcode-select -p >/dev/null 2>&1 || xcode-select --install   # or just run this
#   git clone https://github.com/amtagrwl/dots ~/git/dots       # HTTPS until SSH is set up
#   cd ~/git/dots && ./scripts/bootstrap.sh
#
# Some steps cannot be automated (App Store sign-in, 1Password app login) — the
# script pauses and tells you exactly what to click.

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
say()  { printf "\n\033[1;34m==>\033[0m %s\n" "$*"; }
ok()   { printf "  \033[1;32m✔\033[0m %s\n" "$*"; }
warn() { printf "  \033[1;33m⚠\033[0m %s\n" "$*"; }
pause(){ printf "\n\033[1;33m[manual step]\033[0m %s\n" "$*"; read -r -p "  Press Enter when done… " _; }

[ "$(uname)" = "Darwin" ] || { echo "This bootstrap targets macOS."; exit 1; }

# 1. Xcode Command Line Tools ────────────────────────────────────────────────
say "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then ok "already installed"; else
  xcode-select --install || true
  pause "Finish the Xcode CLT installer dialog."
fi

# 2. Rosetta 2 (Apple Silicon) ────────────────────────────────────────────────
say "Rosetta 2"
if [ "$(uname -m)" = "arm64" ]; then
  if /usr/bin/pgrep -q oahd; then ok "already installed"; else
    softwareupdate --install-rosetta --agree-to-license || warn "Rosetta install skipped/failed"
  fi
else ok "Intel Mac — not needed"; fi

# 3. Homebrew ─────────────────────────────────────────────────────────────────
say "Homebrew"
if command -v brew >/dev/null 2>&1; then ok "already installed"; else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Ensure brew is on PATH for the rest of this script
if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
command -v brew >/dev/null 2>&1 && ok "brew on PATH ($(brew --version | head -1))"

# 4. Submodules (dotbot) ──────────────────────────────────────────────────────
say "Git submodules (dotbot)"
git -C "$REPO_DIR" submodule update --init --recursive && ok "submodules ready"

# 5. App Store sign-in (mas needs the GUI signed in first) ─────────────────────
# Note: `mas` itself is installed by ./install (step 6), and mas 6.x has no CLI
# sign-in/account command — so we can't probe; just prompt for the manual step
# now, before brew bundle tries to install the `mas` apps.
say "Mac App Store sign-in (required for the mas apps: Amphetamine, Bear)"
pause "Open the App Store app and sign in with your Apple ID."

# 5b. AI agent CLIs + repo deps (not brew-managed) ────────────────────────────
say "Claude Code CLI (native installer — not in Brewfile)"
if command -v claude >/dev/null 2>&1 || [ -x "$HOME/.local/bin/claude" ]; then
  ok "already installed"
else
  curl -fsSL https://claude.ai/install.sh | bash || warn "Install manually: https://claude.ai/install.sh"
fi
# Codex CLI comes from the `codex` cask in the Brewfile (installed by ./install).

say "browser-harness repo (CLAUDE.md @-imports ~/git/browser-harness/SKILL.md)"
if [ -d "$HOME/git/browser-harness/.git" ]; then ok "already cloned"; else
  mkdir -p "$HOME/git"
  git clone https://github.com/browser-use/browser-harness "$HOME/git/browser-harness" \
    || warn "Clone failed — CLAUDE.md @-import will be inert until this exists."
fi

# 6. Run the dotbot install (brew bundle + symlinks + scripts) ─────────────────
say "Running ./install (brew bundle + dotbot links + MCP sync)"
( cd "$REPO_DIR" && ./install )

say "Verifying brew bundle applied cleanly"
( cd "$REPO_DIR" && brew bundle check --file Brewfile ) || \
  warn "Some Brewfile entries did not apply — re-run: brew bundle install --file Brewfile"

say "Claude Code plugins (reinstall from marketplaces)"
if command -v claude >/dev/null 2>&1; then
  claude plugin marketplace add anthropics/claude-plugins-official 2>/dev/null || true
  claude plugin marketplace add openai/codex-plugin-cc 2>/dev/null || true
  if claude plugin install codex@openai-codex 2>/dev/null; then
    ok "codex plugin installed"
  else
    warn "Install manually: claude plugin install codex@openai-codex"
  fi
fi

# 7. Interactive auth (cannot be fully scripted) ──────────────────────────────
say "1Password (SSH agent + CLI)"
pause "Open 1Password, sign in, then Settings → Developer → enable 'Use the SSH agent' AND 'Integrate with 1Password CLI'."
"$REPO_DIR/scripts/ensure_1password_ssh.sh" || true
if command -v op >/dev/null 2>&1; then
  if op account list >/dev/null 2>&1; then
    ok "op CLI signed in"
  else
    warn "Run: op signin   (then verify: op read 'op://Personal/Claude Code Github MCP/credential')"
  fi
fi

say "GitHub CLI"
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    ok "gh authenticated"
  else
    warn "Authenticating gh…"
    gh auth login || warn "Run 'gh auth login' manually."
  fi
fi

say "Google Cloud"
if command -v gcloud >/dev/null 2>&1; then
  if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
    ok "gcloud authenticated"
  else
    warn "Run: gcloud auth login && gcloud auth application-default login"
  fi
fi

say "Done. Remaining one-offs to do yourself:"
cat <<'EOF'
  • Switch git remote to SSH once 1Password SSH agent works:
      git -C ~/git/dots remote set-url origin git@github.com:amtagrwl/dots.git
      ssh -T git@github.com   # should greet you by username
  • openclaw / hermes / any local-LLM tooling — install per your own preference.
EOF
