# Bootstrapping this MacBook

Steps to go from a brand-new corp-provisioned Mac to a working toolchain.
Everything is managed by Homebrew: `Brewfile` is the declared package set, and the config trees in this repo are symlinked into `$HOME`.

## 1. Xcode command line tools and Homebrew

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Put Homebrew on `PATH` for the rest of this bootstrap (Apple silicon prefix):

```sh
eval "$(/opt/homebrew/bin/brew shellenv zsh)"
```

Nothing needs appending to `~/.zprofile`: the tracked `zprofile` linked in step 3 already runs `brew shellenv`.

## 2. Install the declared package set

```sh
brew bundle --file ~/dotfiles/Brewfile
```

The `Brewfile` declares its own taps, so no manual `brew tap` is needed.
Verify afterwards:

```sh
brew bundle check --file ~/dotfiles/Brewfile
```

## 3. Link the config files

The config trees at the top level of this repo are symlinked into `$HOME`:

```sh
REPO=~/dotfiles
ln -sfn "$REPO/zsh/zshrc"      ~/.zshrc
ln -sfn "$REPO/zsh/zshenv"     ~/.zshenv
ln -sfn "$REPO/zsh/zprofile"   ~/.zprofile
ln -sfn "$REPO/ghostty"        ~/.config/ghostty
ln -sfn "$REPO/herdr"          ~/.config/herdr
ln -sfn "$REPO/nvim"           ~/.config/nvim
ln -sfn "$REPO/AGENTS.md"      ~/.claude/CLAUDE.md
ln -sfn "$REPO/AGENTS.md"      ~/.codex/AGENTS.md
ln -sfn "$REPO/AGENTS.md"      ~/.config/opencode/AGENTS.md
ln -sfn "$REPO/aws/config"     ~/.aws/config
```

`~/.config/herdr` is a symlink on purpose: herdr writes onboarding and settings state back into its config, and those writes should land in this repo.
AWS credentials and the SSO token cache stay local per machine and are never committed.

## 4. Keg-only tools that need PATH entries

Homebrew keeps `rustup`, `libpq` and `mysql-client` keg-only, so `cargo`, `psql` and `mysql` are not linked into `/opt/homebrew/bin`.
The tracked `zsh/zshenv` handles this, so step 3 is what makes those three commands resolve:

```sh
export PATH="$HOME/go/bin:$HOME/.cargo/bin:/opt/homebrew/opt/rustup/bin:/opt/homebrew/opt/libpq/bin:/opt/homebrew/opt/mysql-client/bin:$PATH"
```

`$HOME/.cargo/bin` is for binaries produced by `cargo install`; the toolchain shims themselves come from the `rustup` keg.
Initialise a toolchain once with `rustup default stable`.

## 5. Tools not available through Homebrew

```sh
npm install -g --allow-scripts=@anthropic-ai/claude-code @anthropic-ai/claude-code
```

The postinstall script is gated by npm and has to be allowed explicitly.

## 6. Full Disk Access for herdr

The herdr server is a daemon that outlives the terminal which started it, so it cannot rely on inheriting Ghostty's file access grant.
Without a grant of its own, every shell herdr spawns is denied access to `~/Documents`, `getcwd` fails with `Operation not permitted`, and agents started in a pane cannot read their own working directory.
Add the binary under System Settings > Privacy & Security > Full Disk Access, using the resolved path:

```sh
readlink -f "$(command -v herdr)"
```

Restart the server afterwards with `herdr server stop`.
herdr is ad-hoc signed with no Team ID, so the grant is keyed to that versioned Cellar path rather than to a code signature, and it has to be re-added after every `brew upgrade herdr`.

## Caps lock

`launchagents/local.keyboard.capslock-to-escape.plist` remaps caps lock to escape.
`hidutil` mappings only last until reboot, so a LaunchAgent re-applies it at every login:

```sh
ln -sfn ~/dotfiles/launchagents/local.keyboard.capslock-to-escape.plist \
        ~/Library/LaunchAgents/local.keyboard.capslock-to-escape.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.keyboard.capslock-to-escape.plist
```

Setting Modifier Keys in System Settings instead would also persist, but it is per-keyboard-device and not reproducible from this repo.

## Shell configuration

`~/.zshrc`, `~/.zshenv` and `~/.zprofile` live in `zsh/` and are symlinked into `$HOME` by step 3.
Between them they carry the shell functions (`work`, `acu`, `tfe`, `coda`, the `ipa` alias), the history options, the `starship`/`direnv`/`fzf`/`zoxide` hooks, the two zsh plugin `source` lines, `DOCKER_HOST` for colima, and the keg-only `PATH` from step 4.

These are live symlinks, so anything that appends to `~/.zprofile` or `~/.zshrc`, such as an installer script or the JetBrains Toolbox app, writes into this repo and shows up as a diff.
That is deliberate, the same arrangement as `~/.config/herdr`.

## Not managed here

IT and MDM own these, and Homebrew must never be pointed at them:
BeyondTrust, Cisco, CrowdStrike Falcon, GlobalProtect, Okta Verify, Iru Self Service, PrivilegeManagement, SquareX, uniFLOW SmartClient, Microsoft Office / Teams / Outlook, OneDrive, the Google Workspace wrappers, and Zoom.
Xcode comes from the App Store.
