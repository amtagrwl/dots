# Runs every time an interactive shell is opened up

export CLICOLOR=1
export PATH=/usr/local/bin:${PATH}
export SVN_EDITOR=nano

# Use autocd if bash version is > 4.0
if [ $(bash -c 'echo $BASH_VERSINFO') -ge 4 ]; then
    shopt -s autocd
fi

# Run .bash_aliases file if found
if [ -r ~/.bash_aliases ]; then
    . ~/.bash_aliases;
fi

# Set up Starship Terminal
if [ -f /usr/local/bin/starship ]; then
    eval "$(starship init bash)"
fi

# Set up FZF
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
