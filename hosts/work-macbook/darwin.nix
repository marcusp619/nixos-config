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
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://claude-code.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
  ];

  # Nonstandard build users (gid 750, uids 751+): the defaults (350/351+)
  # collide with BeyondTrust's _avectodaemon and _defendpoint on this machine.
  ids.gids.nixbld = 750;
  ids.uids.nixbld = 750; # _nixbld1 = base + 1

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

    # CLI tools not packaged in nixpkgs
    brews = [ "newrelic-cli" ];

    # ZenNotes' own flake only builds the desktop app for x86_64-linux, so
    # aarch64-darwin gets it from their Homebrew tap instead.
    taps = [ "zennotes/tap" ];

    casks = [
      "ghostty"
      "obsidian"
      "zennotes"
      "slack"
      # zoom intentionally absent: IT manages it; cask upgrade fights the MDM install
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
