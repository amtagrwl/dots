# Set up Homebrew environment
if command -v brew &> /dev/null; then
 eval "$(brew shellenv)"
fi

# ~/.zshrc: executed by zsh for interactive shells.

# Standard Zsh completion settings
setopt AUTO_MENU
unsetopt MENU_COMPLETE

# Configure zsh-autocomplete behavior (must be BEFORE sourcing)
zstyle ':completion:*' menu select

# Ghostty exports TERM=xterm-ghostty over SSH, but macOS terminfo for that entry can
# miss kcbt/back-tab. zsh-autocomplete assumes it exists and prints:
#   .autocomplete__key-bindings:33: terminfo[kcbt]: parameter not set
# Downgrade TERM only for SSH shells before loading the plugin.
if [[ -n "$SSH_CONNECTION" && "$TERM" == "xterm-ghostty" ]]; then
    export TERM=xterm-256color
fi

# Source zsh-autocomplete plugin (installed via Homebrew)
source "$(brew --prefix)/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"

# Add user bin directories to PATH
if [ -d "$HOME/bin" ]; then
    export PATH="$HOME/bin:${PATH}"
fi

# Add local bin directories to PATH
if [ -d "$HOME/local/bin" ]; then
    export PATH="$HOME/local/bin:${PATH}"
fi

# Add ~/.local/bin to PATH
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:${PATH}"
fi

# Add bun global bin to PATH (for agent-browser, etc.)
if [ -d "$HOME/.bun/bin" ]; then
    export PATH="$HOME/.bun/bin:${PATH}"
fi

# Add /usr/local/bin and /usr/local/sbin (on macOS) to PATH
if [ "$(uname)" = "Darwin" ]; then
    if [ -d "/usr/local/bin" ]; then
        export PATH="/usr/local/bin:${PATH}"
    fi
    if [ -d "/usr/local/sbin" ]; then
        export PATH="/usr/local/sbin:${PATH}"
    fi
else
    # Assuming Linux or other Unix-like
    if [ -d "/usr/local/bin" ]; then
        export PATH="/usr/local/bin:${PATH}"
    fi
fi

# Enable colored output for various commands
export CLICOLOR=1

# --- Zsh specific options ---
setopt AUTO_CD # Change dir by typing directory name

# --- Aliases ---
# Use eza instead of ls (install via Brew)
alias ls='eza --group-directories-first'
alias ll='eza -lagh --group-directories-first --git'
alias l.='eza -ld .* --group-directories-first --git'

# Other aliases
alias grep='grep --color=auto'
alias grepi='grep -i'
alias histgrep="history | grep -i"
alias psagrep="ps aux | grep -i"
alias hist='history'
alias wget='wget -c'

# --- Functions ---
# mkdir && cd function
function mkcd {
    if [ -z "$1" ]; then
        echo "Enter a directory name" >&2
        return 1
    elif [ -d "$1" ]; then
        echo "\`$1' already exists" >&2
        return 1
    else
        mkdir -p "$1" && cd "$1"
    fi
}

# Reset a terminal left in a bad TUI/mouse-reporting state after an SSH/mosh drop.
# Useful when Ghostty starts printing mouse escape sequences like `;151;36M`.
function fixterm {
    printf '\033[?1000l\033[?1002l\033[?1003l\033[?1006l\033[?2004l\033[?25h\033[0m'
    stty sane 2>/dev/null || true
}

# Attach to the iMac Hermes session over Tailscale using mosh + tmux.
# Override per-machine in ~/.zshrc.local if needed:
#   export IMAC_TAILSCALE_HOST=imac
#   export IMAC_TAILSCALE_USER=amtagrwl
#   export HERMES_TMUX_SESSION=hermes
#   export IMAC_MOSH_SERVER=/opt/homebrew/bin/mosh-server
#   export IMAC_TMUX_BIN=/opt/homebrew/bin/tmux
#   export IMAC_TMUX_CONF=$HOME/.tmux.conf
function himac {
    local host="${1:-${IMAC_TAILSCALE_HOST:-imac}}"
    local session="${2:-${HERMES_TMUX_SESSION:-hermes}}"
    local mosh_server="${IMAC_MOSH_SERVER:-/opt/homebrew/bin/mosh-server}"
    local tmux_bin="${IMAC_TMUX_BIN:-/opt/homebrew/bin/tmux}"
    local tmux_conf="${IMAC_TMUX_CONF:-$HOME/.tmux.conf}"
    local target="$host"

    if ! command -v mosh >/dev/null 2>&1; then
        echo "mosh not installed. Run: brew bundle install --file ~/git/dots/Brewfile" >&2
        return 127
    fi

    # Prefer the SSH host alias so ~/.ssh/config can constrain 1Password to the
    # iMac key. For ad-hoc hosts, avoid depending on DNS/MagicDNS by asking
    # Tailscale for the peer IPv4 when available.
    if [[ "$host" != "imac" ]] && command -v tailscale >/dev/null 2>&1; then
        local tailscale_ip
        tailscale_ip="$(tailscale ip -4 "$host" 2>/dev/null | head -n 1)"
        if [[ -n "$tailscale_ip" ]]; then
            target="$tailscale_ip"
        fi
    fi

    if [[ -n "${IMAC_TAILSCALE_USER:-}" ]]; then
        target="${IMAC_TAILSCALE_USER}@${target}"
    fi

    # Use explicit Homebrew paths on the iMac because mosh starts mosh-server via
    # non-interactive SSH, which may not have /opt/homebrew/bin on PATH. Source
    # tmux config before attach so existing tmux servers pick up copy settings.
    mosh --server="$mosh_server" "$target" -- "$tmux_bin" start-server \; source-file "$tmux_conf" \; new-session -A -s "$session"
    local rc=$?
    fixterm
    return "$rc"
}

# OpenTofu/Terraform: share downloaded providers across all worktrees
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
mkdir -p "$TF_PLUGIN_CACHE_DIR" 2>/dev/null

# Source local/machine-specific zsh config if it exists
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi

# AI tool wrappers: resolve GH_MCP_PAT via the 1Password service account
# (headless, never prompts Touch ID, never blocks startup). Token file is
# machine-local; if it or op is missing, launch without the var.
function _agent_gh_pat() {
  local tok="$HOME/.config/agents/op-token"
  { [ -f "$tok" ] && command -v op >/dev/null; } || return 0
  OP_SERVICE_ACCOUNT_TOKEN="$(cat "$tok")" op read 'op://Agents/GitHub MCP PAT/credential' 2>/dev/null
}

# GBrain remote MCP (tailnet HTTP on the iMac) bearer token — same pattern.
function _agent_gbrain_token() {
  local tok="$HOME/.config/agents/op-token"
  { [ -f "$tok" ] && command -v op >/dev/null; } || return 0
  OP_SERVICE_ACCOUNT_TOKEN="$(cat "$tok")" op read 'op://Agents/GBrain MCP Token/credential' 2>/dev/null
}

function claude() {
  GH_MCP_PAT="$(_agent_gh_pat)" GBRAIN_REMOTE_TOKEN="$(_agent_gbrain_token)" command claude "$@"
}

function codex() {
  GH_MCP_PAT="$(_agent_gh_pat)" GBRAIN_REMOTE_TOKEN="$(_agent_gbrain_token)" command codex "$@"
}

# Initialize Starship prompt
eval "$(starship init zsh)"

# Google Cloud SDK (installed via Homebrew cask)
if [ -f '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc'; fi

# fzf — fuzzy finder (Ctrl-T files, Ctrl-R history, Alt-C cd). Sourced AFTER
# zsh-autocomplete so its keybindings win. Uses fd as the file walker.
if command -v fzf &>/dev/null; then
    source <(fzf --zsh)
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi

# zoxide — smarter cd; `z <dir>` jumps by frecency (cd still works as normal).
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi
