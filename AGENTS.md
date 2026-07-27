# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, and others) working in this repository.

## What this is

Personal macOS development environment managed with Homebrew and oh-my-zsh. All dotfiles live in this repo and are symlinked into `~` by `install.sh` / `make links`. No Nix — plain shell scripts.

## Commands

Bootstrap a fresh machine:

```sh
./install.sh
```

Re-create symlinks after moving the repo:

```sh
make links
```

Install/update Homebrew packages:

```sh
make brew          # install from Brewfile
make brew-update   # brew update + bundle
make brew-dump     # overwrite Brewfile with currently-installed packages
```

Apply macOS defaults:

```sh
make macos
```

Write git identities from `.env` into `~/.gitconfig` and `~/.gitconfig.work`:

```sh
make identity
```

Verify all symlinks are healthy:

```sh
make doctor
```

There is no test suite, linter, or build step — this is a config repo, not an app.

## Architecture

`install.sh` / `make links` creates symlinks from the repo into `~`. The three source areas:

- **`.config/zsh/`** — zsh config files. `.zshenv`, `.zprofile`, `.zshrc` are symlinked to `~/`. The whole `.config/zsh/` directory is also symlinked to `~/.config/zsh/` so the other files (`aliases.zsh`, `functions.zsh`, `utilities.zsh`, `macos.zsh`) are accessible.
- **`home/`** — plain dotfiles (`.gitconfig`, `.editorconfig`, `.curlrc`, `.wgetrc`, `.hushlogin`, `.inputrc`, `.gitignore_global`) symlinked to `~/`.
- **`home/.claude/`** — Claude Code config (`settings.json`, `statusline.sh`, `hooks/`) symlinked to `~/.claude/`. Edits to files in `home/.claude/` apply immediately — no reinstall needed.

Machine identity (git name/email) is never hardcoded in the repo. It lives in `.env` (gitignored — see `.env.example`), read by `install.sh` and `make identity` at setup time.

## Known gotchas

- Never commit `.env` — it holds `DOTFILES_GIT_NAME`, `DOTFILES_GIT_EMAIL`, and optionally `WORK_GIT_NAME`, `WORK_GIT_EMAIL`.
- `home/.ssh/config` defines two SSH host aliases (`github.com` for the open account, `github.com-work` for the work account). If you clone via a different SSH config, pushes may authenticate against the wrong account.
- `home/packages.nix` and `.nix` files do not exist in this repo — ignore any references to Nix in stale documentation.

## Updating

- **Homebrew packages**: `make brew-update`
- **macOS defaults**: `make macos`
- **Claude Code config**: edit `home/.claude/` directly — live immediately via symlinks
- **Zsh config**: edit `.config/zsh/` directly — live immediately via symlinks
