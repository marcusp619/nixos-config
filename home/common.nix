{ config, pkgs, lib, inputs, username, ... }:
{
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # core CLI
    ripgrep fd fzf zoxide eza bat jq yq-go tree btop ncdu tmux

    # git helpers
    gh lazygit

    # nix authoring
    nixd alejandra just

    # homelab / k8s
    kubectl k9s kubectx kubernetes-helm kustomize argocd
    sops age velero minio-client cloudflared

    # terminal emulator
    wezterm

    # editor
    neovim

    # AI agents
    claude-code
    inputs.herdr.packages.${pkgs.system}.default
  ];

  # ── symlink live config dirs out of the store ────────────────────────────
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/files/wezterm";

  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/files/nvim";

  # ── AGENTS.md → every agent tool's expected location ─────────────────────
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/files/AGENTS.md";

  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/files/AGENTS.md";

  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/files/AGENTS.md";

  # ── git ───────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings.user.name = "marcusp619";
    settings.user.email = "marcusp619@gmail.com";
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
  };

  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.fzf.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
