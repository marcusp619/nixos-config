{ pkgs, ... }:
{
  home.packages = with pkgs; [
    firefox
    obsidian
    spotify
    appimage-run
  ];
}
