if [ $USER == "root" ]; then
    PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# '
else
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

alias ls='ls -axF --color --group-directories-first'
alias ll='ls -lh --time-style=long-iso'
alias grep='grep -s --color=auto'
alias du='du -sh'
alias df='df -h'
alias syu='sudo pacman -Syu'

export EDITOR=vim
export HISTSIZE=
export HISTFILESIZE=
export HISTCONTROL=erasedups:ignorespace

function c() {
  cd $1
  ls -AFx --group-directories-first --color
}

export TRASH=/home/$USER/.trash
function trash() {
    DATE=$(date +%Y_%m_%d)
    TIME=$(date +%H_%M_%S)
    mkdir -p $TRASH/$DATE/$TIME
    mv -t $TRASH/$DATE/$TIME $*
}
