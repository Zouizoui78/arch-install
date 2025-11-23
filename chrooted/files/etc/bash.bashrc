# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Prevent doublesourcing
if [[ -z "${BASHRCSOURCED}" ]] ; then
  BASHRCSOURCED="Y"
  if [ $USER == "root" ]; then
      PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# '
  else
      PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
  fi
fi

if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  . /usr/share/bash-completion/bash_completion
fi

alias ls='ls -AxF --color --group-directories-first'
alias ll='ls -lh --time-style=long-iso'
alias grep='grep -s --color=auto'

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
