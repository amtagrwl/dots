# Runs only with login shell (Most uses)

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	    . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin directories
if [ -d "$HOME/bin" ]; then
    export PATH="$HOME/bin:${PATH}"
fi

# set PATH so it includes user's local bin directories
if [ -d "$HOME/local/bin" ]; then
    export PATH="$HOME/local/bin:${PATH}"
fi

# set PATH so it includes user's private ~/.local/bin if it exists
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:${PATH}"
fi

# set PATH so it includes pip3 user installs on Mac
if [ "$(uname)" == "Darwin" ]; then
        # Mac OSX
    if [ -d "$HOME/Library/Python/3.8/bin" ]; then
    	export PATH="~/Library/Python/3.8/bin:${PATH}"
    fi
    if [ -d "/usr/local/sbin" ]; then
    	export PATH="/usr/local/sbin:${PATH}"
    fi
fi
