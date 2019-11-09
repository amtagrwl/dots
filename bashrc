# Runs every time an interactive shell is opened up 

export CLICOLOR=1
export PATH=/usr/local/bin:$PATH
export SVN_EDITOR=nano

# Use autocd if bash version is > 4.0 
[ ${BASH_VERSINFO[0]} -ge 4 ] && shopt -s autocd

# Run .bash_aliases file if found 
[ -r ~/.bash_aliases ] && . ~/.bash_aliases
