# Bootstrapping the work MacBook (Homebrew)

Steps to go from a brand-new corp-provisioned Mac to a working toolchain.
This host is managed by Homebrew, not Nix: `Brewfile` in this directory is the declared package set.
The two personal hosts in this repo are still NixOS and are driven by `flake.nix`.

## Background: why this host isn't on Nix

Nix needs `/nix` backed by a dedicated store.
On this machine Kandji MDM plus BeyondTrust EPM block `diskutil apfs addVolume` against the physical container, so `diskutil mount "Nix Store"` fails with `SUIS premount dissented`, a deprecated but still enforced `SystemUIServer` "harddisk-internal" mount policy.
The workaround was to back `/nix` with an `hdiutil` sparse image, which worked but left the store on a file-backed volume that had to be re-attached by a LaunchDaemon on every boot.
That setup was retired on 2026-09-07 in favour of Homebrew.
Nothing here depends on Nix any more.

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
brew bundle --file ~/nix-config/hosts/work-macbook/Brewfile
```

The `Brewfile` declares its own taps, so no manual `brew tap` is needed.
Verify afterwards:

```sh
brew bundle check --file ~/nix-config/hosts/work-macbook/Brewfile
```

## 3. Link the shared config files

`home/files/` holds the config trees shared with the NixOS hosts.
On this host they are plain symlinks, created by hand rather than by home-manager:

```sh
REPO=~/nix-config/home/files
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
Nix used to put them on `PATH` directly.
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

## Caps lock

`home/files/launchagents/local.keyboard.capslock-to-escape.plist` remaps caps lock to escape, replacing nix-darwin's `system.keyboard.remapCapsLockToEscape`.
`hidutil` mappings only last until reboot, so a LaunchAgent re-applies it at every login:

```sh
ln -sfn ~/nix-config/home/files/launchagents/local.keyboard.capslock-to-escape.plist \
        ~/Library/LaunchAgents/local.keyboard.capslock-to-escape.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.keyboard.capslock-to-escape.plist
```

Setting Modifier Keys in System Settings instead would also persist, but it is per-keyboard-device and not reproducible from this repo.

## Shell configuration

`~/.zshrc`, `~/.zshenv` and `~/.zprofile` live in `home/files/zsh/` and are symlinked into `$HOME` by step 3.
Between them they carry the shell functions (`work`, `acu`, `tfe`, `coda`, the `ipa` alias), the history options, the `starship`/`direnv`/`fzf`/`zoxide` hooks, the two zsh plugin `source` lines, `DOCKER_HOST` for colima, and the keg-only `PATH` from step 4.
They replace what `programs.zsh` in `home/common.nix` generates on the NixOS hosts, which is why that module is not used here.

These are live symlinks, so anything that appends to `~/.zprofile` or `~/.zshrc`, such as an installer script or the JetBrains Toolbox app, writes into this repo and shows up as a diff.
That is deliberate, the same arrangement as `~/.config/herdr`.

## Not managed here

IT and MDM own these, and Homebrew must never be pointed at them:
BeyondTrust, Cisco, CrowdStrike Falcon, GlobalProtect, Okta Verify, Iru Self Service, PrivilegeManagement, SquareX, uniFLOW SmartClient, Microsoft Office / Teams / Outlook, OneDrive, the Google Workspace wrappers, and Zoom.
Xcode comes from the App Store.
