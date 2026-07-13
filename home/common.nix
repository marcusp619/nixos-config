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

    # editor
    neovim

    # AI agents
    claude-code
    inputs.herdr.packages.${pkgs.system}.default
  ];

  # ── symlink live config dirs out of the store ────────────────────────────
  # Ghostty is the terminal everywhere — the app comes from a cask on darwin
  # and pkgs.ghostty on linux (see personal-apps.nix).
  home.file.".config/ghostty".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/files/ghostty";

  # Mutable symlink on purpose: herdr writes onboarding/settings state back
  # into its config, and those writes should land in this repo.
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix-config/home/files/herdr";

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
    settings.pull.ff = "only";
    settings.init.defaultBranch = "main";
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
  programs.zoxide.enable   = true;
  programs.fzf.enable      = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
