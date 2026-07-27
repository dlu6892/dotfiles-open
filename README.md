# dotfiles

Personal macOS development environment managed with Homebrew and oh-my-zsh.

> **These dotfiles are intended for my own environment. Use at your own risk.**

## Directory Structure

```
dotfiles/
├── install.sh               # Bootstrap: Homebrew, packages, symlinks, git identity, macOS defaults
├── Brewfile                 # All packages (brews + casks + fonts)
├── macos-defaults.sh        # macOS system defaults (Finder, Dock, keyboard, etc.)
├── .env.example             # Template for git identity vars (copy to .env, gitignored)
├── .config/
│   └── zsh/
│       ├── .zshenv          # Env vars + PATH (symlinked to ~/.zshenv)
│       ├── .zprofile        # Login shell hooks (symlinked to ~/.zprofile)
│       ├── .zshrc           # Interactive shell: oh-my-zsh, plugins, zoxide
│       ├── aliases.zsh      # Aliases (navigation, git, system, network)
│       ├── functions.zsh    # Custom shell functions
│       ├── utilities.zsh    # Utility aliases and compatibility fixes
│       └── macos.zsh        # macOS-specific aliases and functions
└── home/
    ├── .export              # Exported env vars (GHQ_ROOT, EDITOR, LANG, etc.)
    ├── .gitignore_global    # Global gitignore (symlinked to ~/.gitignore)
    ├── .editorconfig        # Editor settings
    ├── .inputrc             # Readline configuration
    ├── .curlrc              # Curl configuration
    ├── .wgetrc              # Wget configuration
    ├── .ssh/
    │   └── config           # SSH host aliases for open/work GitHub accounts
    └── .claude/             # Claude Code settings, statusline, hooks
```

## Installation

### Prerequisites

- macOS (Apple Silicon)
- Xcode Command Line Tools (`install.sh` will install if missing)

### Quick Start

```sh
git clone git@github.com-work:clu_mntv/dotfiles.git ~/Developer/.ghq/github.com-work/clu_mntv/dotfiles
cd ~/Developer/.ghq/github.com-work/clu_mntv/dotfiles
cp .env.example .env   # fill in git identity vars (see .env.example)
./install.sh
exec zsh
```

`install.sh` will:
1. Install Xcode Command Line Tools if absent (re-run after install completes)
2. Install Homebrew if absent
3. Run `brew bundle` — installs all brews, casks, and fonts from `Brewfile`
4. Install [oh-my-zsh](https://ohmyz.sh) if absent
5. Symlink all dotfiles to `~` (backs up existing non-symlink files to `*.backup`)
6. Run `make identity` — writes git identities from `.env` into `~/.gitconfig` and `~/.gitconfig.work`
7. Apply macOS defaults via `macos-defaults.sh`
8. Create `~/Developer/.ghq/github.com/` and `~/Developer/.ghq/github.com-work/` directories

### Applying changes

After editing any dotfile, changes are live immediately (symlinks, not copies).

To re-create symlinks after moving the repo:
```sh
make links
```

To add/remove packages, edit `Brewfile` then:
```sh
make brew
```

To re-apply macOS defaults:
```sh
make macos
```

To verify all symlinks are healthy:
```sh
make doctor
```

## GitHub Accounts

This repo is set up for two GitHub accounts accessed via SSH host aliases:

| Alias | Account | SSH Key | ghq root |
|---|---|---|---|
| `github.com` | open (dlu6892) | `~/.ssh/id_ed25519_dlu6892` | `~/Developer/.ghq/github.com/` |
| `github.com-work` | work (clu_mntv) | `~/.ssh/id_ed25519` | `~/Developer/.ghq/github.com-work/` |

`home/.ssh/config` defines both hosts. Git identity is scoped automatically:
- repos under `.ghq/github.com/` → open identity (global `~/.gitconfig`)
- repos under `.ghq/github.com-work/` → work identity (`~/.gitconfig.work` via `includeIf`)

### SSH setup

Add both keys to the macOS Keychain (one-time, after generating):

```sh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_dlu6892   # open
ssh-add --apple-use-keychain ~/.ssh/id_ed25519            # work
```

Verify:
```sh
ssh -T git@github.com        # Hi dlu6892!
ssh -T git@github.com-work   # Hi clu_mntv!
```

### Cloning repos

`GHQ_ROOT` is set to `~/Developer/.ghq`, so plain `ghq get` routes repos there automatically:

```sh
# open account — goes to ~/Developer/.ghq/github.com/dlu6892/repo
ghq get git@github.com:dlu6892/repo

# work account — use ghq-work to route into github.com-work/
ghq-work get git@github.com-work:clu_mntv/repo
```

Scoped listing:
```sh
ghq list        # all repos under ~/Developer/.ghq
ghq-work list   # repos under .ghq/github.com-work/
```

### Git identity

Identities are sourced from `.env` (gitignored). To re-apply after editing `.env`:

```sh
make identity
```

This writes the open identity into `~/.gitconfig` and the work identity into `~/.gitconfig.work`.

## Customization

- **Aliases/functions**: edit `.config/zsh/aliases.zsh` or `.config/zsh/functions.zsh`
- **Packages**: edit `Brewfile`
- **Machine-local overrides**: create `~/.zshrc.local` (not tracked, sourced last)

## Updating

- **Homebrew packages**: `brew upgrade` or `brew bundle --file=Brewfile`
- **macOS defaults**: `./macos-defaults.sh`
- **Mac App Store apps**: `mas upgrade`

## Resources

* [oh-my-zsh](https://ohmyz.sh) — zsh framework
* [ghq](https://github.com/x-motemen/ghq) — repository management

## License

This project is licensed under MIT License - see the LICENSE file for details.
