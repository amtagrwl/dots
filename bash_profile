# Runs only with login shell (Most uses)

# Run .bashrc file if found 
[ -r ~/.bashrc ] && . ~/.bashrc

# set PATH so it includes user's private bin directories
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private ~/.local/bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi