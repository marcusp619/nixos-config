{ config, pkgs, username, ... }:
{
  # Placeholder for the Mac — we'll flesh this out after the desktop is up.

  environment.systemPackages = [ pkgs.vim ];

  # macOS GUI apps go through Homebrew casks (via the nix-homebrew module) or `mas`
  # for App Store apps. Wire this up later:
  # homebrew = {
  #   enable = true;
  #   casks = [ "raycast" "rectangle" ];
  # };

  # A couple of sane macOS defaults to show the pattern — expand to taste.
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    NSGlobalDomain.InitialKeyRepeat = 15;
    NSGlobalDomain.KeyRepeat = 2;
  };

  users.users.${username}.home = "/Users/${username}";
  system.primaryUser = username;

  # NOTE: if you install *Determinate* Nix on the Mac (its graphical installer),
  # it manages nix.conf itself — then set `nix.enable = false;` here and use the
  # determinate nix-darwin module instead of the line below.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Set to the current nix-darwin stateVersion (bump if a rebuild tells you to).
  system.stateVersion = 5;
}
