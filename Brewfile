# Brewfile — managed by Dotbot (`brew bundle install --file Brewfile`)
# To add/remove packages: edit this file BY HAND — never `brew bundle dump` (it strips
#       comments/grouping and resurrects the pruned entries below). Put new entries in the
#       right section with a one-line "why"; record removals in the `# Pruned` block.
# NOTE: `brew bundle` continues past failures. After install, run
#       `brew bundle check --file Brewfile` to catch anything that didn't apply
#       (common causes: not signed into the App Store for `mas`, no Cursor for `vscode`).
# NOTE: `./install` runs `brew bundle install --no-upgrade` so setup doesn't
#       upgrade every already-installed formula/cask. Upgrade deliberately with
#       `brew bundle upgrade --file Brewfile` or targeted `brew upgrade <name>`.
# NOTE: `brew bundle` prefetches EVERY download before installing any package, so one
#       slow/CDN-throttled cask (e.g. spotify) can stall the whole bundle for minutes with
#       nothing installed yet. This is expected — not a hang.

# ── Shell / core CLI ─────────────────────────────────────────────────────────
brew "bun"
brew "node"                # agent-browser's global bin has a `#!/usr/bin/env node` shebang (engines>=24); bun ships no node shim — do NOT prune as "unused"
brew "eza"                 # modern ls (aliased in zshrc)
brew "gh"
brew "gnupg"
brew "mas"
brew "mosh"                # resilient interactive shell over Tailscale/UDP for laptop↔iMac TUI sessions
brew "python@3.13"
brew "starship"
brew "tailscale"           # tailnet CLI + userspace networking for private MacBook↔iMac access
brew "tmux"                # persistent remote shells; keeps Hermes alive across disconnects
brew "uv"
brew "zsh-autocomplete"

# ── Modern CLI (added: agent-friendly terminal) ──────────────────────────────
brew "ripgrep"             # rg — every coding agent shells out to this
brew "fd"                  # fast, gitignore-aware find (fzf backend)
brew "fzf"                 # fuzzy finder (Ctrl-T/Ctrl-R/Alt-C; init in zshrc)
brew "bat"                 # syntax-highlighted cat / pager
brew "jq"                  # JSON (also required by claude statusline-command.sh)
brew "yq"                  # jq for YAML/TOML (config-dense repo)
brew "git-delta"           # rich git diff pager (configured in gitconfig_dotfiles)
brew "zoxide"              # smarter cd (`z <dir>`; init in zshrc)
brew "wget"                # the zshrc `wget -c` alias was dead without this

# ── Cloud / IaC / DB (install on demand — not part of default setup) ─────────
# Uncomment per machine when you actually need the GCP/IaC/DB work stack:
#   brew "terraform"
#   brew "opentofu"
#   brew "cloud-sql-proxy"
#   brew "cloudflared"
#   brew "postgresql@17"
#   brew "libpq"
#   brew "mcp-toolbox"

# ── Lint / file utilities ────────────────────────────────────────────────────
brew "shellcheck"
brew "hadolint"
brew "exiftool"
brew "poppler"             # pdftotext et al.
brew "oasdiff"             # OpenAPI diff

# ── Core apps ────────────────────────────────────────────────────────────────
cask "1password"
cask "1password-cli"
cask "gcloud-cli"
cask "ghostty"
cask "alfred"
cask "contexts"
cask "maccy"
cask "airbuddy"
cask "qlmarkdown"

# ── AI / dev tools ───────────────────────────────────────────────────────────
cask "cursor"
cask "claude"              # Claude desktop (pairs with Claude Code + Bear MCP)
cask "codex"               # Codex CLI
cask "codex-app"           # Codex desktop (heavily used)
cask "docker-desktop"      # needs sudo (symlinks CLI into /usr/local/bin) — run brew bundle in a TTY

# ── Browsers ─────────────────────────────────────────────────────────────────
cask "arc"                     # primary browser
cask "google-chrome"           # required by browser-harness (attaches to running Chrome)
cask "thebrowsercompany-dia"   # Dia (cask token is NOT `dia`)

# ── Dictation / productivity ─────────────────────────────────────────────────
cask "wispr-flow"

# ── Comms / media / vpn ──────────────────────────────────────────────────────
cask "whatsapp"
cask "spotify"
cask "zoom"                # pkg installer — prompts for sudo (run brew bundle in a TTY)
cask "openvpn-connect"     # pkg installer — prompts for sudo (run brew bundle in a TTY)

# Pruned (re-add if wanted):
#   cask "dbeaver-community" — not needed (per request)
#   cask "conductor"         — not needed (per request)
#   cask "superwhisper"      — not needed (per request; using Wispr Flow)
#   cask "chatgpt"       — ChatGPT.app trashed (you use Codex + openai.chatgpt ext)
#   cask "linear-linear" — Linear.app trashed (web app via Arc)
#   cask "antigravity"   — app trashed
#   cask "lm-studio"     — app trashed (no local-LLM stack)
#   cask "discord"       — never opened
#   cask "chatgpt-atlas" — never opened
#   brew "gemini-cli"    — last run Oct 2025
#   brew "glab"          — GitLab CLI never configured (you use gh)
#   brew "pipx"          — superseded by `uv tool`

# ── Mac App Store (sign into the App Store app AND already own these apps, else
#    `mas install` fails with a misleading "sudo: a terminal is required" error;
#    the App Store GUI is the reliable fallback) ────────────────────────────────
mas "Amphetamine", id: 937984704
mas "Bear", id: 1091189122
# iWork omitted (unused on source Mac): Keynote 409183694, Numbers 409203825, Pages 409201541

# ── Cursor / VS Code extensions (brew bundle detects the `cursor` CLI) ────────
vscode "anthropic.claude-code"
vscode "anysphere.cursorpyright"
vscode "charliermarsh.ruff"
vscode "esbenp.prettier-vscode"
vscode "mechatroner.rainbow-csv"
vscode "ms-azuretools.vscode-containers"
vscode "ms-azuretools.vscode-docker"
vscode "ms-python.debugpy"
vscode "ms-python.python"
# vscode "ms-python.vscode-pylance"  # OMITTED: Pylance is MS-proprietary, absent from Open VSX, and
#   license-locked to official MS products — uninstallable in Cursor, so it kept `brew bundle check`
#   permanently red. `anysphere.cursorpyright` (above) is Cursor's drop-in replacement.
vscode "openai.chatgpt"
vscode "stkb.rewrap"
vscode "tamasfe.even-better-toml"
vscode "tomoki1207.pdf"
vscode "vscodevim.vim"
