{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    discord
    bitwarden-desktop
    bambu-studio
    vlc
    ghostty

    # notes — flake only builds the desktop app for x86_64-linux;
    # work-macbook (aarch64-darwin) gets it via the zennotes/tap Homebrew cask.
    inputs.zennotes.packages.${pkgs.system}.zennotes-desktop
  ];
}
