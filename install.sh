#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source .env if present (holds git identity — see .env.example)
if [ -f "$DOTFILES_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "$DOTFILES_DIR/.env"
  set +a
fi

# Prompt for any identity vars still unset
if [ -z "${DOTFILES_USERNAME:-}" ]; then
  read -rp "macOS username [$(whoami)]: " DOTFILES_USERNAME
  DOTFILES_USERNAME="${DOTFILES_USERNAME:-$(whoami)}"
fi
if [ -z "${DOTFILES_GIT_NAME:-}" ]; then
  default_git_name="$(git config --global user.name 2>/dev/null || true)"
  read -rp "Git user.name${default_git_name:+ [$default_git_name]}: " DOTFILES_GIT_NAME
  DOTFILES_GIT_NAME="${DOTFILES_GIT_NAME:-$default_git_name}"
fi
if [ -z "${DOTFILES_GIT_EMAIL:-}" ]; then
  default_git_email="$(git config --global user.email 2>/dev/null || true)"
  read -rp "Git user.email${default_git_email:+ [$default_git_email]}: " DOTFILES_GIT_EMAIL
  DOTFILES_GIT_EMAIL="${DOTFILES_GIT_EMAIL:-$default_git_email}"
fi
export DOTFILES_USERNAME DOTFILES_GIT_NAME DOTFILES_GIT_EMAIL DOTFILES_DIR
export WORK_GIT_NAME="${WORK_GIT_NAME:-}" WORK_GIT_EMAIL="${WORK_GIT_EMAIL:-}"

echo "==> Setting up dev environment for ${DOTFILES_USERNAME}"

# 1. Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  echo "==> Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "Xcode tools installing — re-run this script when done."
  exit 0
fi

# 2. Homebrew
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 3. Install packages
echo "==> Installing packages from Brewfile..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

# 4. oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing oh-my-zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 5. Symlink dotfiles
echo "==> Symlinking dotfiles..."

symlink() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "${dst}.backup"
    echo "  Backed up $dst → ${dst}.backup"
  fi
  ln -sfn "$src" "$dst"
  echo "  $dst → $src"
}

# Zsh config files (live in .config/zsh/ in the repo)
for f in .zshenv .zprofile .zshrc; do
  symlink "$DOTFILES_DIR/.config/zsh/$f" "$HOME/$f"
done

# Plain dotfiles (live in home/ in the repo)
for f in .gitconfig .editorconfig .curlrc .wgetrc .hushlogin .inputrc; do
  [ -f "$DOTFILES_DIR/home/$f" ] && symlink "$DOTFILES_DIR/home/$f" "$HOME/$f"
done

# Global gitignore
symlink "$DOTFILES_DIR/home/.gitignore_global" "$HOME/.gitignore"

# Zsh config directory (aliases, functions, etc.)
mkdir -p "$HOME/.config"
symlink "$DOTFILES_DIR/.config/zsh" "$HOME/.config/zsh"

# Claude Code config (live-edit symlinks — edits to either path apply immediately)
mkdir -p "$HOME/.claude"
symlink "$DOTFILES_DIR/home/.claude/settings.json" "$HOME/.claude/settings.json"
symlink "$DOTFILES_DIR/home/.claude/hooks"          "$HOME/.claude/hooks"
symlink "$DOTFILES_DIR/home/.claude/statusline.sh"  "$HOME/.claude/statusline.sh"

# SSH config
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
symlink "$DOTFILES_DIR/home/.ssh/config" "$HOME/.ssh/config"

# 7. Git identity
echo "==> Configuring git identity..."
make -C "$DOTFILES_DIR" identity

# 8. macOS defaults
echo "==> Applying macOS defaults..."
bash "$DOTFILES_DIR/macos-defaults.sh"

# 9. Dev directories
mkdir -p "$HOME/Developer/python-projects"
mkdir -p "$HOME/Developer/python-scripts"
mkdir -p "$HOME/Developer/python-templates"
mkdir -p "$HOME/Developer/projects"
mkdir -p "$HOME/Developer/sandbox"
mkdir -p "$HOME/Developer/.ghq/github.com"
mkdir -p "$HOME/Developer/.ghq/github.com-work"

echo ""
echo "==> Done! Run:  exec zsh"
