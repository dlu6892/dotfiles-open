# dotfiles

Personal macOS development environment managed with Homebrew and oh-my-zsh. Dotfiles live in this repo and are symlinked into `~` by `install.sh`.

> **These dotfiles are intended for my own environment. Use at your own risk.**

---

## How it works

```
dotfiles-open/                         ~/ (home directory)
│
├── .config/zsh/
│   ├── .zshenv        ──────────────► ~/.zshenv
│   ├── .zprofile      ──────────────► ~/.zprofile
│   ├── .zshrc         ──────────────► ~/.zshrc
│   ├── aliases.zsh  ─┐
│   ├── functions.zsh  ├─────────────► ~/.config/zsh/  (whole dir symlinked)
│   ├── utilities.zsh  │              sourced by .zshrc
│   └── macos.zsh    ─┘
│
├── home/
│   ├── .gitconfig     ──────────────► ~/.gitconfig
│   ├── .gitignore_global ───────────► ~/.gitignore
│   ├── .editorconfig  ──────────────► ~/.editorconfig
│   ├── .curlrc        ──────────────► ~/.curlrc
│   ├── .wgetrc        ──────────────► ~/.wgetrc
│   ├── .inputrc       ──────────────► ~/.inputrc
│   ├── .hushlogin     ──────────────► ~/.hushlogin
│   ├── .ssh/config    ──────────────► ~/.ssh/config
│   └── .claude/
│       ├── settings.json ───────────► ~/.claude/settings.json
│       ├── statusline.sh ───────────► ~/.claude/statusline.sh
│       └── hooks/     ──────────────► ~/.claude/hooks/
│
├── .env  (gitignored) ──────────────► read by install.sh + shell on startup
│   DOTFILES_GIT_NAME, DOTFILES_GIT_EMAIL
│   WORK_GIT_NAME, WORK_GIT_EMAIL (optional)
│
├── Brewfile           ──────────────► brew bundle
├── macos-defaults.sh  ──────────────► applied by install.sh / make macos
└── install.sh         ──────────────► full bootstrap (run once on a new machine)
```

All symlinks are created by `install.sh` (first run) or `make links` (re-run after moving the repo). Edits to any file in `.config/zsh/` or `home/.claude/` are live immediately — no reinstall.

---

## Claude Code status line

`home/.claude/statusline.sh` renders a two-line status bar at the bottom of every Claude Code session:

```
🧠 claude-sonnet-4-5  │  📁 dotfiles-open  │  🌿 main +2 ~1
▓▓▓▓░░░░░░ 40%  │  💰 $0.12  │  ⏱️  3m 22s
```

| Segment | Description |
|---|---|
| `🧠 claude-sonnet-4-5` | Model in use |
| `📁 dotfiles-open` | Working directory (basename) |
| `🌿 main` | Git branch |
| `+2` (green) | Staged file count |
| `~1` (yellow) | Unstaged modified file count |
| `▓▓▓▓░░░░░░ 40%` | Context window usage — green → yellow → red |
| `$0.12` | Cumulative session cost |
| `⏱️ 3m 22s` | Total session wall-clock time |
| `⏳ 5h:12% 7d:8%` | Rate limit usage (Pro/Max only, hidden otherwise) |

Git state is cached per-session for 5 seconds to keep the status line fast.

Wired in `home/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "$HOME/.claude/statusline.sh",
    "padding": 1
  }
}
```

---

## Directory structure

```
dotfiles-open/
├── install.sh               # Bootstrap: Homebrew, oh-my-zsh, symlinks, git identity, macOS defaults
├── Makefile                 # Targets: links, brew, macos, identity, doctor
├── Brewfile                 # All packages (brews + casks + fonts)
├── macos-defaults.sh        # macOS system defaults (Finder, Dock, keyboard, etc.)
├── .env.example             # Template for git identity vars (copy to .env, gitignored)
├── AGENTS.md                # AI agent guide (architecture, commands, gotchas)
├── CLAUDE.md                # Claude Code entry point → points to AGENTS.md
│
├── .config/zsh/
│   ├── .zshenv              # Env vars + PATH
│   ├── .zprofile            # Login shell hooks
│   ├── .zshrc               # Interactive shell: oh-my-zsh, plugins, zoxide
│   ├── aliases.zsh          # Navigation, git, system, network aliases
│   ├── functions.zsh        # Custom shell functions
│   ├── utilities.zsh        # Utility aliases and compatibility fixes
│   └── macos.zsh            # macOS-specific aliases and functions
│
├── home/
│   ├── .gitconfig           # Git config (identity written by make identity)
│   ├── .gitignore_global    # Global gitignore
│   ├── .editorconfig        # Editor settings
│   ├── .curlrc / .wgetrc    # curl/wget defaults
│   ├── .inputrc             # Readline configuration
│   ├── .hushlogin           # Suppress login message
│   ├── .ssh/config          # SSH host aliases (github.com + github.com-work)
│   └── .claude/             # Claude Code config (symlinked to ~/.claude/)
│       ├── settings.json    # Theme, statusline, permissions, hooks
│       ├── statusline.sh    # Custom status line script
│       └── hooks/           # PreToolUse hooks (e.g. block-destructive-git.sh)
```

---

## Installation

### Prerequisites

- macOS (Apple Silicon)
- Xcode Command Line Tools — `install.sh` will install if absent

### Quick start

```sh
git clone git@github.com:dlu6892/dotfiles-open.git \
  ~/Developer/.ghq/github.com/dlu6892/dotfiles-open
cd ~/Developer/.ghq/github.com/dlu6892/dotfiles-open
cp .env.example .env   # fill in git identity vars
./install.sh
exec zsh
```

`install.sh` does in order:

1. Xcode Command Line Tools (if absent — re-run after install completes)
2. Homebrew (if absent)
3. `brew bundle` — installs all packages from `Brewfile`
4. oh-my-zsh (if absent)
5. Symlinks all dotfiles into `~` (backs up existing non-symlink files to `*.backup`)
6. `make identity` — writes git identities from `.env` into `~/.gitconfig` / `~/.gitconfig.work`
7. `macos-defaults.sh` — applies macOS defaults
8. Creates `~/Developer/` subdirectories

### Applying changes

After editing any dotfile: changes are live immediately (symlinks, not copies).

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

---

## GitHub accounts

Two accounts via SSH host aliases:

| Alias | Account | SSH Key | ghq root |
|---|---|---|---|
| `github.com` | open (dlu6892) | `~/.ssh/id_ed25519_dlu6892` | `~/Developer/.ghq/github.com/` |
| `github.com-work` | work (clu_mntv) | `~/.ssh/id_ed25519` | `~/Developer/.ghq/github.com-work/` |

Git identity is scoped automatically:
- `.ghq/github.com/` → open identity (global `~/.gitconfig`)
- `.ghq/github.com-work/` → work identity (`~/.gitconfig.work` via `includeIf gitdir:`)

### SSH setup (one-time)

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

```sh
ghq get git@github.com:dlu6892/repo          # open — ~/Developer/.ghq/github.com/...
ghq-work get git@github.com-work:clu_mntv/repo   # work — ~/Developer/.ghq/github.com-work/...
```

---

## Customization

- **Aliases / functions**: edit `.config/zsh/aliases.zsh` or `functions.zsh` — live immediately
- **Packages**: edit `Brewfile`, then `make brew`
- **Claude Code config**: edit `home/.claude/settings.json` or `statusline.sh` — live immediately
- **Machine-local overrides**: create `~/.zshrc.local` (not tracked, sourced last by `.zshrc`)

---

## Updating

| What | How |
|---|---|
| Homebrew packages | `make brew-update` |
| macOS defaults | `make macos` |
| Mac App Store apps | `mas upgrade` |

---

## Resources

- [oh-my-zsh](https://ohmyz.sh)
- [ghq](https://github.com/x-motemen/ghq)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

## License

MIT — see [LICENSE](./LICENSE).
