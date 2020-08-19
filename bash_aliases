# alias expansion prefix
alias watch='watch '
alias sudo='sudo '

# ls aliases
if [ "$(uname)" == "Darwin" ]; then
        # Mac OSX
	alias ls='ls -p'
else
        # ubuntu
	alias ls='ls -p --color=auto'
fi
alias ll='ls -la -h'
alias l.='ls -ld .*'

# cd aliases
alias cd..='cd ..'
alias cd-='cd -'
alias ..='cd ..'

# grep aliases
alias grep='grep --color=auto'
alias grepi='grep -i'
alias histgrep='history | grepi'
alias psagrep='ps aux | grepi'

# history aliases
alias hist='history'

# wget aliases
if hash axel 2>/dev/null; then
    alias wget='axel'
else
    alias wget='wget -c'
fi

# mkdir && cd function alias
function mkcd {
    if [ ! -n "$1" ]; then
        echo "Enter a directory name"
    elif [ -d $1 ]; then
        echo "\`$1' already exists"
    else
        mkdir $1 && cd $1
    fi
}
