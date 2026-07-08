{ config, pkgs, username, ... }:
{
  users.users.${username}.home = "/Users/${username}";
  system.primaryUser = username;

  nixpkgs.config.allowUnfree = true;

  # Upstream Nix installed with NIX_VOLUME_CREATE=0 + synthetic.conf symlink
  # (/nix -> /System/Volumes/Data/nix) because Kandji MDM blocks the Nix Store
  # volume mount. If that ever changes to Determinate Nix, set nix.enable = false.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" username ];

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  # GUI apps via Homebrew casks — more reliable than nixpkgs for mac apps.
  # NOT listed (IT/MDM owns them — never manage): BeyondTrust, Cisco, CrowdStrike
  # Falcon, GlobalProtect, Okta Verify, Iru, PrivilegeManagement, SquareX,
  # uniFLOW, Microsoft Office/Teams/Outlook, OneDrive, Google Workspace apps.
  homebrew = {
    enable = true;
    # "none" while migrating off brew formulae; flip to "uninstall" once the
    # nix setup is proven so brew prunes everything not declared here.
    onActivation.cleanup = "none";

    casks = [
      "ghostty"
      "obsidian"
      "slack"
      "zoom"
      "cursor"
      "datagrip"
      "figma"
      "firefox"
      "google-chrome"
      "zen"
      "keeper-password-manager"
      "rectangle" # replaces abandoned Spectacle
      "git-credential-manager"
    ];
  };

  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    NSGlobalDomain.InitialKeyRepeat = 15;
    NSGlobalDomain.KeyRepeat = 2;
  };

  # Set to the current nix-darwin stateVersion (bump if a rebuild tells you to).
  system.stateVersion = 5;
}
