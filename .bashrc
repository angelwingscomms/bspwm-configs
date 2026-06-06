# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

export BROWSER=chromium

# opencode
export PATH=/home/ed/.opencode/bin:$PATH

# dotfiles bare repo
alias githome='git --git-dir=$HOME/.config/bspwm-configs.git --work-tree=$HOME'
