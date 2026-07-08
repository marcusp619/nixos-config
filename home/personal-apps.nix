{ pkgs, ... }:
{
  home.packages = with pkgs; [
    discord
    bitwarden-desktop
    bambu-studio
    vlc
  ];
}
