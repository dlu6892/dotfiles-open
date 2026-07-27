# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, and others — `CLAUDE.md` symlinks here) working in this repository.

## What this is

Personal macOS development environment managed with [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager) on Nix flakes. Targets a single Apple Silicon machine at a time — there is no multi-host matrix, just one `darwinConfigurations` entry keyed by the current machine's hostname.

## Commands

Apply config after editing any `.nix` file (`--impure` is required — see Machine identity below):

```sh
sudo --preserve-env=DOTFILES_USERNAME,DOTFILES_HOSTNAME,DOTFILES_GIT_NAME,DOTFILES_GIT_EMAIL,DOTFILES_DIR,WORK_GIT_NAME,WORK_GIT_EMAIL \
  darwin-rebuild switch --flake .#$(hostname -s) --impure
```

Check the flake evaluates without applying anything (still needs the same env vars + `--impure`):

```sh
nix flake check --no-build --impure --show-trace
```

Bump pinned nixpkgs/inputs (a rebuild alone won't fetch newer package versions):

```sh
nix flake update            # or: nix flake update nixpkgs
```

Fresh-machine bootstrap (Xcode CLT → Nix via Determinate installer → Homebrew → nix-darwin):

```sh
./install.sh
```

There is no test suite, linter, or build step beyond `nix flake check` — this is a config repo, not an app.

## Architecture

Two Nix layers plus a plain-dotfiles layer:

- **`darwin/`** — system-level, applied by nix-darwin: `configuration.nix` (users, hostname, `nix.enable = false` because Determinate Nix owns the Nix install/daemon, not nix-darwin), `defaults.nix` (macOS defaults via `system.defaults`), `homebrew.nix` (GUI casks + `mas` brew, auto-upgraded via `homebrew.onActivation.upgrade`).
- **`home/`** — user-level, applied by home-manager, imported from `home/default.nix`: `shell.nix` (zsh/oh-my-zsh/plugins/`sessionVariables`/`initContent`), `git.nix`, `python.nix`, `node.nix`, `packages.nix`, `misc.nix`.
- **`.config/zsh/*.zsh`** (`aliases.zsh`, `functions.zsh`, `utilities.zsh`, `macos.zsh`) — plain zsh, not Nix, sourced from `home/shell.nix`'s `initContent`. Edit these directly for aliases/functions rather than touching Nix syntax.
- Machine-local escape hatches: `~/.zshrc.local` (sourced last by `initContent`, untracked) and `home/misc.nix`'s note about deferred `.aws/` dotfiles.
- `home/.claude/` — tracked Claude Code config (`settings.json`, `statusline.sh`, `hooks/`). `home/misc.nix` links `~/.claude/{settings.json,statusline.sh,hooks}` to it via `mkOutOfStoreSymlink` (not a store copy), so edits to either path apply immediately without a rebuild.

### Machine identity: no username/hostname/git-identity/repo-path literals in the repo

`flake.nix` does **not** hardcode `username`/`hostname`, and `home/git.nix` does not hardcode git `user.name`/`user.email`. Instead `flake.nix` reads env vars via `builtins.getEnv`:

- `DOTFILES_USERNAME`, `DOTFILES_HOSTNAME`, `DOTFILES_GIT_NAME`, `DOTFILES_GIT_EMAIL`, `DOTFILES_DIR` — **required**, via `getEnvOrThrow` (throws a descriptive error if unset). `DOTFILES_USERNAME`/`DOTFILES_HOSTNAME` are passed to `darwin/configuration.nix` and `home/default.nix` as `username`/`hostname` (`users.users.${username}`, `networking.hostName`, `home.username`/`homeDirectory`). `DOTFILES_GIT_NAME`/`DOTFILES_GIT_EMAIL` become `gitName`/`gitEmail` for `home/git.nix`'s `programs.git.settings.user.*`. `DOTFILES_DIR` is the repo's absolute checkout path, used by `home/misc.nix` for `mkOutOfStoreSymlink` targets (those need a real on-disk path, not a Nix store path).
- `WORK_GIT_NAME`, `WORK_GIT_EMAIL` — **optional**, via `getEnvOrNull` (returns `null` rather than throwing). Become `workGitName`/`workGitEmail`; `home/git.nix` only adds a `programs.git.includes` entry (work identity scoped to `gitdir:~/Developer/work/`) when `WORK_GIT_EMAIL` is set. This is the template to follow for any other optional per-machine value — required values throw, optional ones return `null` and the consuming module conditionally no-ops.

Where these env vars come from:

- **`.env`** (gitignored, never committed — see `.env.example` for the template) holds the identity values that can't be auto-detected: `DOTFILES_GIT_NAME`, `DOTFILES_GIT_EMAIL`, `WORK_GIT_NAME`, `WORK_GIT_EMAIL`.
- `DOTFILES_USERNAME`/`DOTFILES_HOSTNAME` are **not** in `.env` — they're computed live (`whoami`/`hostname -s`) so they can't go stale. `DOTFILES_DIR` also isn't in `.env` — it's derived from the invoking script's own location (`install.sh`) or baked in as a literal at the last successful build (`home/shell.nix`'s `sessionVariables`).
- `install.sh` sources `.env` first (if present), then prompts for anything still unset (defaulting to `whoami`/`hostname -s`/existing `git config --global user.*`), exports everything, and re-exports through `sudo --preserve-env=...` since nix-darwin activation runs as root.
- `home/shell.nix`'s `initContent` sources `$DOTFILES_DIR/.env` fresh on every interactive shell (before `.zshrc.local`), so a plain shell has the identity vars available for a manual rebuild without re-running `install.sh`. `DOTFILES_USERNAME`/`DOTFILES_HOSTNAME` stay live-computed in `sessionVariables`; `DOTFILES_DIR` stays baked in there too (chicken-and-egg — you need to already know the repo path to find `.env`).

Consequences for anyone editing this repo:

- `builtins.getEnv` only works under **impure evaluation** — every `nix flake check`, `darwin-rebuild switch`, etc. against this flake needs `--impure`, or required vars throw `"<VAR> is not set..."`.
- If you add a new required per-machine/per-person value, follow the `getEnvOrThrow` pattern; for an optional one (not every machine needs it), follow the `getEnvOrNull` pattern — either way: env var → `flake.nix` → `specialArgs`/`extraSpecialArgs` → consuming module, never a literal in a tracked file. Add required identity-like values to `.env.example` (and `.env`), not auto-detectable ones like username/hostname/repo-path.

### Known gotchas encoded in comments (don't "fix" these without re-reading why)

- `darwin/configuration.nix`: `nix.enable = false` — Determinate Nix manages the Nix daemon; letting nix-darwin manage it too conflicts. `time.timeZone` is deliberately left unmanaged (it fights macOS's automatic location-based timezone via `systemsetup -settimezone`).
- `home/packages.nix`: no `openssh` — installing it lets home-manager's PATH ordering shadow the system OpenSSH at `/usr/bin/ssh-copy-id`/`/usr/bin/ssh`, which doesn't understand Apple's `UseKeychain` `~/.ssh/config` directive and breaks `git push` over SSH.
- `home/python.nix` / `home/node.nix`: deliberately keep only core interpreters + package managers; framework/linter CLIs are installed on-demand (`uv tool install`, `pnpm add -g`) rather than pinned globally — see the comments in those files for the intended on-demand commands.
- No `programs.neovim`/`home/neovim.nix` module: this repo doesn't yet track a `.config/nvim/` directory, and `xdg.configFile."nvim".source` requires that path to exist at eval time. `neovim` is installed as a plain package in `home/packages.nix` instead — `EDITOR` still resolves to `nvim`. Add a real `home/neovim.nix` + `.config/nvim/` once there's actual Neovim config worth tracking, following the same pattern as `home/shell.nix`'s `xdg.configFile."zsh"`.

## Updating

- Homebrew casks/brews: auto-upgraded every rebuild, no separate step.
- Nix-managed CLI packages (`home/packages.nix` etc.): pinned by `flake.lock` — bump via `nix flake update` then rebuild.
- Nix itself: managed by the Determinate installer, not this repo (`nix.enable = false`).
- Anything installed outside this repo (drag-installed apps, Mac App Store apps): not tracked; update manually or via `mas upgrade`.
