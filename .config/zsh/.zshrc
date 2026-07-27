# ~/.zshrc - Zsh Interactive Shell Configuration

[ -z "$PS1" ] && return

# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

setopt AUTO_CD
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY

HISTSIZE=32768
SAVEHIST=32768

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  plugins=(git macos docker docker-compose)
  source "$ZSH/oh-my-zsh.sh"
fi

# Homebrew zsh plugins
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# zoxide — smarter cd
eval "$(zoxide init zsh)"

# GPG (needs a TTY, only valid in interactive shells)
export GPG_TTY=$(tty)

# Source git identity and optional work identity (gitignored — see .env.example)
if [[ -n "$DOTFILES_DIR" && -f "$DOTFILES_DIR/.env" ]]; then
  set -a
  source "$DOTFILES_DIR/.env"
  set +a
fi

# Modular zsh config
[ -f "$HOME/.config/zsh/aliases.zsh"   ] && source "$HOME/.config/zsh/aliases.zsh"
[ -f "$HOME/.config/zsh/functions.zsh" ] && source "$HOME/.config/zsh/functions.zsh"
[ -f "$HOME/.config/zsh/utilities.zsh" ] && source "$HOME/.config/zsh/utilities.zsh"
if [ "$(uname)" = "Darwin" ]; then
  [ -f "$HOME/.config/zsh/macos.zsh" ] && source "$HOME/.config/zsh/macos.zsh"
fi

# Machine-local overrides (untracked)
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
