# Machine Inventory — Work MacBook (2026-07-07)

Source of truth for the Nix flake + home-manager migration. Mark items:
`[k]` keep · `[d]` drop · `[?]` unsure. Items already marked are my recommendations —
change anything you disagree with.

Only **top-level** tools are listed. The ~150 other brew formulae (libpng, openssl,
icu4c, …) are dependencies; Nix resolves those automatically and they should NOT be
declared.

---

## 1. Core CLI tools (home-manager `home.packages` / `programs.*`)

- [k] git + gh + lazygit + git-filter-repo
- [k] neovim (LazyVim config in ~/.config/nvim — port as home-manager dotfile)
- [k] fzf, fd, ripgrep, jq, grep (GNU), gnu-sed, coreutils, wget
- [k] tmux → **replaced by herdr** (keep config around until herdr is proven)
- [d] zellij — superseded by herdr
- [k] tree-sitter, universal-ctags
- [d] oh-my-posh — installed but .zshrc uses oh-my-zsh robbyrussell theme; appears unused
- [k] zsh plugins: zsh-syntax-highlighting, zsh-autosuggestions, zsh-completions
  (home-manager `programs.zsh` replaces oh-my-zsh entirely)
- [k] font: JetBrainsMono Nerd Font (ghostty) + Hack Nerd Font (cask) — pick one?

## 2. Cloud / infra / containers

- [k] colima + docker + docker-buildx + docker-compose (colima is your engine; DOCKER_HOST set in .zshenv)
- [k] terraform via tfenv → in Nix: pin terraform version per-project in flakes instead
- [d] m1-terraform-provider-helper — obsolete on modern providers?
- [d] helm, k9s (kube configs present)
- [k] aws-sam-cli, aws-vault, chamber
- [k] mkcert
- [d] ngrok
- [k] newrelic-cli
- [k] hey (load testing)
- [k] qemu + lima (lima ships with colima; standalone qemu still needed?)
- [d] merve (brew formula — do you know what this is? not a common package)

## 3. Languages & runtimes

### Node

- [k] node — **29 versions installed via nvm.** In Nix: one global default (24.x) + per-project versions via flake devShells. nvm goes away entirely.
- [k] pnpm
- [d] yarn — still used anywhere, or fully on pnpm?
- [d] nx — global install needed, or per-project dep?
- [k] typescript, typescript-language-server, vscode-langservers-extracted (globals)

### Go

- [k] go + gopls, goimports, staticcheck, air, migrate/golang-migrate, golangci-lint, sqlc
- [d] swag, templ, go-outline, godoc — still active?

### Rust

- [k] rust toolchain (rustup → replaced by fenix/rust-overlay or plain nixpkgs rust)
- [k] rust-analyzer, cargo-watch, cargo-expand, sqlx-cli, taplo
- [d] cargo-leptos, trunk, leptosfmt — active Leptos project?
- [d] cargo-audit, cargo-tarpaulin, cargo-miri
- [d] rls — deprecated years ago, rust-analyzer replaced it
- [d] rustlings — learning exercises, reinstall on demand

### Python

- [k] python — currently pyenv (3.10.10 global) + 5 brew pythons (3.10–3.14).
  In Nix: one default python3 + per-project flakes. pyenv goes away.

### PHP

- [d] php 8.1 + composer + lando + ddev + terminus — is PHP/Drupal/Pantheon work still active?
- [d] php 7.2, 7.3, 7.4 — all EOL since 2022
- [d] Local.app (WordPress local dev)

### .NET / other

- [d] dotnet + mono + nuget + upgrade-assistant — still doing .NET work?
- [d] powershell — installed 3 ways (formula, cask, app); if kept, keep once
- [d] zig
- [k] lua + luarocks + lua-language-server (needed by neovim config — keep if LazyVim)
- [d] haskell-language-server — no ghc installed; orphan?

## 4. Databases

- [k] mysql-client (single version)
- [d] mysql@8.0 server — running locally, or does colima/ddev handle DBs?
- [d] mysql-client@8.0 — duplicate of mysql-client
- [k] redis (cli history exists — used recently)
- [k] libpq (psql client)

## 5. AI / agent tooling

- [k] claude (Claude Code, ~/.local/bin) + Claude.app
- [k] herdr — **new: replaces tmux/zellij** (not in nixpkgs yet? verify; may need
  a flake input or the install script)
- [d] codex (brew) + Codex.app
- [d] opencode
- [d] cursor-agent + Cursor.app
- [d] "agent" binary in ~/.local/bin

## 6. Terminals — pick ONE

Configs exist for: ghostty (active, configured), warp (cask), iterm2, kitty, wezterm.

- [k] **Ghostty** — recommended: it's the one with a real config, pairs well with herdr
- [d] Warp, and delete stale iterm2/kitty/wezterm configs

## 7. GUI apps (nix-darwin `homebrew.casks` or nixpkgs where available)

### Keep

- [k] Ghostty, Obsidian, Slack, zoom
- [k] Cursor, DataGrip (or JetBrains Toolbox — one or the other), Figma
- [k] Firefox / Chrome / Zen — three browsers; prune to two?
- [k] Keeper Password Manager
- [k] Xcode (App Store — outside nix; needed for CLT anyway)

### Review

- [d] FileZilla — replaceable by CLI sftp/rsync
- [d] Spectacle — abandoned since 2019; replace with Rectangle or AeroSpace (both in nix)
- [d] Windows App, Grammarly Desktop, JetBrains Toolbox
- [k] Google Docs/Sheets/Slides/Drive wrappers, OneDrive
- [k] Microsoft Word/Excel/PowerPoint/OneNote/Outlook/Teams — corp-required?

### IT-managed — EXCLUDE from nix (MDM installs these)

BeyondTrust, Cisco, Falcon (CrowdStrike), GlobalProtect, Okta Verify,
Iru Self Service, PrivilegeManagement, SquareX, Zero Trust Browser Extension,
uniFLOW SmartClient

## 8. Shell config to port to home-manager

- .zshrc functions: `_pick_dir`/`work`/`acu`/`tfe` (fzf dir jumpers), `coda` (AWS SSO
  - SSM tunnel), `ipa` alias — port to `programs.zsh.initExtra` (work-mac only module)
- oh-my-zsh → drop; home-manager zsh + the 3 plugins reproduces it
- nvm lazy-load block → delete (nix replaces)
- PATH exports (go, cargo, mysql-client, libpq, pnpm, obsidian) → home-manager sessionPath
- .zshenv: DOCKER_HOST=colima sock, cargo env
- git config: name/email (⚠ see SECURITY below), pull.ff=only, init.defaultBranch=main,
  GCM for dev.azure.com

## ⚠ SECURITY — do before anything else

1. `~/.gitconfig` contains a **plaintext GitHub PAT** in an `insteadOf` URL rewrite.
   Revoke it at github.com/settings/tokens, delete that block, use gh/GCM auth instead.
2. `~/.git-credentials` and `~/.netrc` exist — audit and remove stored secrets.
   Never port these files into the nix repo.
