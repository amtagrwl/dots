# Brewfile — managed by Dotbot (`brew bundle install --file Brewfile`)
# To capture new packages: brew bundle dump --file=./Brewfile --force
# NOTE: `brew bundle` continues past failures. After install, run
#       `brew bundle check --file Brewfile` to catch anything that didn't apply
#       (common causes: not signed into the App Store for `mas`, no Cursor for `vscode`).

# ── Shell / core CLI ─────────────────────────────────────────────────────────
brew "bun"
brew "eza"                 # modern ls (aliased in zshrc)
brew "gh"
brew "gnupg"
brew "mas"
brew "python@3.13"
brew "starship"
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
cask "docker-desktop"

# ── Browsers ─────────────────────────────────────────────────────────────────
cask "arc"                     # primary browser
cask "google-chrome"           # required by browser-harness (attaches to running Chrome)
cask "thebrowsercompany-dia"   # Dia (cask token is NOT `dia`)

# ── Dictation / productivity ─────────────────────────────────────────────────
cask "wispr-flow"

# ── Comms / media / vpn ──────────────────────────────────────────────────────
cask "whatsapp"
cask "spotify"
cask "zoom"
cask "openvpn-connect"

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

# ── Mac App Store (requires being signed into the App Store app first) ────────
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
vscode "ms-python.vscode-pylance"
vscode "openai.chatgpt"
vscode "stkb.rewrap"
vscode "tamasfe.even-better-toml"
vscode "tomoki1207.pdf"
vscode "vscodevim.vim"
