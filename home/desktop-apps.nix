{ pkgs, ... }:
{
  home.packages = with pkgs; [
    firefox
    obsidian
    spotify
    appimage-run

    # QML module required by Plasma's Sound KCM (kcm_pulseaudio) and other
    # KCMs; kcmshell6/systemsettings aren't wrapped with it since it's a
    # runtime dependency of a dlopen'd plugin, not a build input of kcmutils.
    kdePackages.kirigami-addons
  ];
}
