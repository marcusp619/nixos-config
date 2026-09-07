{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [ ../lib/create-symlink.nix ];

  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # core CLI
    ripgrep fd fzf zoxide eza bat jq yq-go tree btop ncdu tmux

    # git helpers
    gh lazygit

    # nix authoring
    nixd alejandra just

    # node — nodejs_latest tracks whatever nixpkgs currently considers newest
    nodejs_latest

    # editor
    neovim

    # AI agents — claude-code from its own flake (fresher than nixpkgs;
    # binary cache claude-code.cachix.org is configured per-host)
    inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default

    # homelab CLIs
    kubectl
    k9s
    kubernetes-helm
    argocd
    sops
    age
    velero
    minio-client
    cloudflared
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    # Claude desktop app — not in nixpkgs; community flake.
    # macOS gets it via Homebrew cask on work-macbook.
    inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop
  ];

  # ── symlink live config dirs out of the store ────────────────────────────
  # Ghostty is the terminal everywhere — the app comes from a cask on darwin
  # and pkgs.ghostty on linux (see personal-apps.nix).
  home.file.".config/ghostty".source =
    config.lib.meta.createSymlink "home/files/ghostty";

  # Mutable symlink on purpose: herdr writes onboarding/settings state back
  # into its config, and those writes should land in this repo.
  home.file.".config/herdr".source =
    config.lib.meta.createSymlink "home/files/herdr";

  home.file.".config/nvim".source =
    config.lib.meta.createSymlink "home/files/nvim";

  # ── AGENTS.md → every agent tool's expected location ─────────────────────
  home.file.".claude/CLAUDE.md".source =
    config.lib.meta.createSymlink "home/files/AGENTS.md";

  home.file.".codex/AGENTS.md".source =
    config.lib.meta.createSymlink "home/files/AGENTS.md";

  home.file.".config/opencode/AGENTS.md".source =
    config.lib.meta.createSymlink "home/files/AGENTS.md";

  # ── git ───────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings.user.name = "marcusp619";
    settings.user.email = "marcusp619@gmail.com";
    settings.pull.ff = "only";
    settings.init.defaultBranch = "main";
    settings.credential."https://github.com".helper =
      "!${pkgs.gh}/bin/gh auth git-credential";
    settings.credential."https://gist.github.com".helper =
      "!${pkgs.gh}/bin/gh auth git-credential";
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  # ── shell ─────────────────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      setopt AUTO_CD
      setopt INTERACTIVE_COMMENTS
    '';
  };

  programs.starship.enable = true;
  programs.zoxide.enable   = true;
  programs.fzf.enable      = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
