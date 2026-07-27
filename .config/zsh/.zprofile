# ~/.zprofile - Zsh Login Shell Configuration
# Sourced for login shells only (terminal.app, ssh, etc.)

# Homebrew shell env for login shells on Apple Silicon (not needed if .zshenv already ran,
# but harmless to repeat and ensures a clean login shell gets the full brew env).
if [ -f "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
