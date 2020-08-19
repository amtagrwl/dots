# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	    . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin directories
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:${PATH}"
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