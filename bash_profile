# Runs only with login shell (Most uses)

# Run .bashrc file if found 
[ -r ~/.bashrc ] && . ~/.bashrc
# Run .bash_aliases file if found 
[ -r ~/.bash_aliases ] && . ~/.bash_aliases

# set PATH so it includes user's private bin directories
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private ~/.local/bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi