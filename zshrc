# ~/.zshrc: executed by zsh for interactive shells.

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
alias ll='eza -lgh --group-directories-first --git'
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

# Source local/machine-specific zsh config if it exists
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi 