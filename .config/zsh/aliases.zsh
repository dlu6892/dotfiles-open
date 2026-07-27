# ~/.config/zsh/aliases.zsh
# Zsh aliases

# -----------------------
# Navigation
# -----------------------

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

alias d="cd ~/Documents"
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias dev="cd ~/Developer"

# -----------------------
# Git
# -----------------------

alias g="git"
alias gst="git status"
alias ga="git add"
alias grm="git rm"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"

# -----------------------
# System
# -----------------------

alias h="history"
alias j="jobs"
alias c="tr -d '\n' | pbcopy"  # Trim new lines and copy to clipboard
alias week="date +%V"
alias timer="echo \"Timer started. Stop with Ctrl-D.\" && date && time cat && date"

# -----------------------
# Network
# -----------------------

alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"

# -----------------------
# File Operations
# -----------------------

alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"

# Modern ls alternatives (using eza if available)
if command -v eza >/dev/null 2>&1; then
    alias ls="eza"
    alias ll="eza -l -g --icons"
    alias la="eza -la -g --icons"
    alias lt="eza -l -g --icons --tree"
    alias lsd="eza -l -g --icons -D"
else
    # Fallback to regular ls with colors
    alias ls="ls -G"
    alias ll="ls -lhG"
    alias la="ls -lahG"
    alias lsd="ls -lhG | grep --color=never '^d'"
fi

# -----------------------
# git Repo Management
# -----------------------

alias ghq-work='GHQ_ROOT=~/Developer/.ghq/github.com-work/ ghq'

# -----------------------
# Quick Notes
# -----------------------

alias qd='quick_daily_note'
