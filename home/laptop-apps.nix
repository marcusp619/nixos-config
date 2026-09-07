{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    firefox
    discord
    bitwarden-desktop
    vlc
    ghostty
    zed-editor

    # notes — flake only builds the desktop app for x86_64-linux;
    # work-macbook (aarch64-darwin) gets it via the zennotes/tap Homebrew cask.
    inputs.zennotes.packages.${pkgs.stdenv.hostPlatform.system}.zennotes-desktop
  ];
}
