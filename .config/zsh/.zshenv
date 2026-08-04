# ~/.zshenv - Zsh Environment Variables
# This file is always sourced (even for non-interactive shells)

# DOTFILES_DIR — strip the known suffix from the symlink target so no hardcoded
# path lives in the repo. Falls back gracefully if .zshenv was copied vs linked.
_zshenv_link="$(readlink "$HOME/.zshenv" 2>/dev/null)"
if [[ -n "$_zshenv_link" ]]; then
  export DOTFILES_DIR="${_zshenv_link%/.config/zsh/.zshenv}"
fi
unset _zshenv_link

# Editor
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
else
  export EDITOR="vim"
fi

# Terminal
export TERM="xterm-256color"
export CLICOLOR=1
export LSCOLORS="exfxcxdxbxegedabagacad"

# Locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Node.js
export NODE_REPL_HISTORY="$HOME/.node_history"
export NODE_REPL_HISTORY_SIZE="32768"
export NODE_REPL_MODE="sloppy"

# Python
export PYTHONIOENCODING="UTF-8"
export PYTHONDONTWRITEBYTECODE=1

# History
export HISTSIZE=32768
export HISTFILESIZE=32768
export HISTCONTROL="ignoreboth"

# Less / man
export LESS_TERMCAP_md=$'\e[1;33m'
export MANPAGER="less -X"

# macOS
if [ "$(uname)" = "Darwin" ]; then
  export COPYFILE_DISABLE=1
fi

# Go
export GOPATH="$HOME/go"

# ghq
export GHQ_ROOT="$HOME/Developer/.ghq"

# PATH
PATH="$HOME/bin:$PATH"
PATH="$HOME/.local/bin:$PATH"

# Homebrew (Apple Silicon first, Intel fallback)
if [ -d "/opt/homebrew/bin" ]; then
  PATH="/opt/homebrew/bin:$PATH"
  PATH="/opt/homebrew/sbin:$PATH"
elif [ -d "/usr/local/bin" ]; then
  PATH="/usr/local/bin:$PATH"
  PATH="/usr/local/sbin:$PATH"
fi

# Python 3.12 (brew-managed, keg-only — not auto-linked)
[ -d "/opt/homebrew/opt/python@3.12/libexec/bin" ] && \
  PATH="/opt/homebrew/opt/python@3.12/libexec/bin:$PATH"

# Node 22 (brew-managed, keg-only — not auto-linked)
[ -d "/opt/homebrew/opt/node@22/bin" ] && \
  PATH="/opt/homebrew/opt/node@22/bin:$PATH"

# MySQL 8.4 client (keg-only — must precede any mysql@9 on PATH)
[ -d "/opt/homebrew/opt/mysql-client@8.4/bin" ] && \
  PATH="/opt/homebrew/opt/mysql-client@8.4/bin:$PATH"

# Flyway CLI (installed by dre-cicd-internal/scripts/localdev-setup.py)
[ -d "$HOME/.local/share/flyway" ] && \
  PATH="$HOME/.local/share/flyway:$PATH"

# Language runtimes
PATH="$GOPATH/bin:$PATH"
PATH="$HOME/.cargo/bin:$PATH"

export PATH
