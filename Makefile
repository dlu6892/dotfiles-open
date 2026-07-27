.DEFAULT_GOAL := help
DOTFILES_DIR  := $(CURDIR)

.PHONY: help install brew brew-check brew-dump brew-update macos links identity doctor

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Full bootstrap — Homebrew, oh-my-zsh, dotfile links, macOS defaults
	./install.sh

# ---------------------------------------------------------------------------
# Homebrew
# ---------------------------------------------------------------------------

brew: ## Install/update packages from Brewfile
	brew bundle --file=$(DOTFILES_DIR)/Brewfile

brew-check: ## Check Brewfile is fully satisfied (exits 1 if not)
	brew bundle check --file=$(DOTFILES_DIR)/Brewfile

brew-dump: ## Overwrite Brewfile with currently-installed packages
	brew bundle dump --force --file=$(DOTFILES_DIR)/Brewfile

brew-update: ## brew update then brew bundle
	brew update && brew bundle --file=$(DOTFILES_DIR)/Brewfile

# ---------------------------------------------------------------------------
# macOS defaults
# ---------------------------------------------------------------------------

macos: ## Apply macOS system defaults (restarts Dock/Finder/SystemUIServer)
	bash $(DOTFILES_DIR)/macos-defaults.sh

# ---------------------------------------------------------------------------
# Dotfile symlinks
# ---------------------------------------------------------------------------

links: ## Re-create all dotfile symlinks (safe to re-run; backs up conflicts)
	@_sym() { \
		src="$$1"; dst="$$2"; \
		if [ -e "$$dst" ] && [ ! -L "$$dst" ]; then \
			mv "$$dst" "$$dst.backup" && printf "  backed up $$dst\n"; \
		fi; \
		ln -sfn "$$src" "$$dst" && printf "  $$dst -> $$src\n"; \
	}; \
	for f in .zshenv .zprofile .zshrc; do \
		_sym "$(DOTFILES_DIR)/.config/zsh/$$f" "$(HOME)/$$f"; \
	done; \
	for f in .gitconfig .editorconfig .curlrc .wgetrc .hushlogin .inputrc .export; do \
		src="$(DOTFILES_DIR)/home/$$f"; \
		[ -f "$$src" ] && _sym "$$src" "$(HOME)/$$f"; \
	done; \
	_sym "$(DOTFILES_DIR)/home/.gitignore_global" "$(HOME)/.gitignore"; \
	mkdir -p "$(HOME)/.config"; \
	_sym "$(DOTFILES_DIR)/.config/zsh" "$(HOME)/.config/zsh"; \
	mkdir -p "$(HOME)/.claude"; \
	_sym "$(DOTFILES_DIR)/home/.claude/settings.json" "$(HOME)/.claude/settings.json"; \
	_sym "$(DOTFILES_DIR)/home/.claude/hooks"         "$(HOME)/.claude/hooks"; \
	_sym "$(DOTFILES_DIR)/home/.claude/statusline.sh" "$(HOME)/.claude/statusline.sh"; \
	mkdir -p "$(HOME)/.ssh" && chmod 700 "$(HOME)/.ssh"; \
	_sym "$(DOTFILES_DIR)/home/.ssh/config" "$(HOME)/.ssh/config"

# ---------------------------------------------------------------------------
# Git identity
# ---------------------------------------------------------------------------

identity: ## Write git identities from .env into ~/.gitconfig and ~/.gitconfig.work
	@if [ ! -f "$(DOTFILES_DIR)/.env" ]; then \
		printf "  \033[31m✗\033[0m .env not found — copy .env.example and fill in values\n"; exit 1; \
	fi; \
	set -a; . "$(DOTFILES_DIR)/.env"; set +a; \
	if [ -z "$${DOTFILES_GIT_NAME:-}" ] || [ -z "$${DOTFILES_GIT_EMAIL:-}" ]; then \
		printf "  \033[31m✗\033[0m DOTFILES_GIT_NAME and DOTFILES_GIT_EMAIL must be set in .env\n"; exit 1; \
	fi; \
	git config --global user.name  "$$DOTFILES_GIT_NAME"; \
	git config --global user.email "$$DOTFILES_GIT_EMAIL"; \
	printf "  \033[32m✓\033[0m open:  $$DOTFILES_GIT_NAME <$$DOTFILES_GIT_EMAIL>\n"; \
	if [ -n "$${WORK_GIT_EMAIL:-}" ]; then \
		printf '[user]\n\tname = %s\n\temail = %s\n' \
			"$${WORK_GIT_NAME:-$$DOTFILES_GIT_NAME}" "$$WORK_GIT_EMAIL" \
			> "$(HOME)/.gitconfig.work"; \
		git config --global "includeIf.gitdir:$(HOME)/Developer/.ghq/github.com-work/.path" \
			"$(HOME)/.gitconfig.work"; \
		printf "  \033[32m✓\033[0m work:  %s <%s> (scoped to .ghq/github.com-work)\n" \
			"$${WORK_GIT_NAME:-$$DOTFILES_GIT_NAME}" "$$WORK_GIT_EMAIL"; \
	fi

# ---------------------------------------------------------------------------
# Doctor
# ---------------------------------------------------------------------------

doctor: ## Verify all expected symlinks exist and point into this repo
	@ok=0; fail=0; \
	_chk() { \
		if [ -L "$$1" ] && [ "$$(readlink "$$1")" = "$$2" ]; then \
			printf "  \033[32m✓\033[0m $$1\n"; ok=$$((ok+1)); \
		else \
			printf "  \033[31m✗\033[0m $$1\n    expected -> $$2\n"; fail=$$((fail+1)); \
		fi; \
	}; \
	_chk "$(HOME)/.zshenv"              "$(DOTFILES_DIR)/.config/zsh/.zshenv"; \
	_chk "$(HOME)/.zprofile"            "$(DOTFILES_DIR)/.config/zsh/.zprofile"; \
	_chk "$(HOME)/.zshrc"               "$(DOTFILES_DIR)/.config/zsh/.zshrc"; \
	_chk "$(HOME)/.config/zsh"          "$(DOTFILES_DIR)/.config/zsh"; \
	_chk "$(HOME)/.gitconfig"           "$(DOTFILES_DIR)/home/.gitconfig"; \
	_chk "$(HOME)/.gitignore"           "$(DOTFILES_DIR)/home/.gitignore_global"; \
	_chk "$(HOME)/.editorconfig"        "$(DOTFILES_DIR)/home/.editorconfig"; \
	_chk "$(HOME)/.curlrc"              "$(DOTFILES_DIR)/home/.curlrc"; \
	_chk "$(HOME)/.wgetrc"              "$(DOTFILES_DIR)/home/.wgetrc"; \
	_chk "$(HOME)/.inputrc"             "$(DOTFILES_DIR)/home/.inputrc"; \
	_chk "$(HOME)/.claude/settings.json" "$(DOTFILES_DIR)/home/.claude/settings.json"; \
	_chk "$(HOME)/.claude/hooks"        "$(DOTFILES_DIR)/home/.claude/hooks"; \
	_chk "$(HOME)/.claude/statusline.sh" "$(DOTFILES_DIR)/home/.claude/statusline.sh"; \
	_chk "$(HOME)/.ssh/config"          "$(DOTFILES_DIR)/home/.ssh/config"; \
	if [ -z "$$(git config --global user.email 2>/dev/null)" ]; then \
		printf "  \033[31m✗\033[0m git identity not set — run: make identity\n"; fail=$$((fail+1)); \
	else \
		printf "  \033[32m✓\033[0m git identity: $$(git config --global user.name) <$$(git config --global user.email)>\n"; ok=$$((ok+1)); \
	fi; \
	printf "\n  %d ok, %d failed\n" "$$ok" "$$fail"; \
	[ "$$fail" -eq 0 ]
