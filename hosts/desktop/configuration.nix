{ config, pkgs, inputs, username, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # ── Boot ─────────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── AMD CPU + Radeon GPU ──────────────────────────────────────────────────
  hardware.cpu.amd.updateMicrocode = true;
  hardware.graphics = {
    enable    = true;
    enable32Bit = true;
  };

  # ── Networking ────────────────────────────────────────────────────────────
  networking.hostName            = "desktop";
  networking.networkmanager.enable = true;

  # ── Audio (PipeWire) ──────────────────────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable      = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };

  # ── Desktop (Plasma 6 + SDDM) ─────────────────────────────────────────────
  services.xserver.enable               = true;
  services.displayManager.sddm.enable   = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb = {
    layout  = "us";
    options = "caps:escape";
  };

  # ── Services ──────────────────────────────────────────────────────────────
  services.openssh.enable    = true;
  services.tailscale.enable  = true;
  virtualisation.docker.enable = true;

  # ── Gaming ────────────────────────────────────────────────────────────────
  programs.steam = {
    enable             = true;
    remotePlay.openFirewall = true;
  };
  programs.gamemode.enable = true;
  hardware.steam-hardware.enable = true;

  services.sunshine = {
    enable      = true;
    openFirewall = true;
    capSysAdmin  = true;
  };

  # ── Auto-upgrade ──────────────────────────────────────────────────────────
  system.autoUpgrade = {
    enable = true;
    flake  = "github:marcusp619/nixos-config#desktop";
    dates  = "daily";
  };

  # ── Zram swap ─────────────────────────────────────────────────────────────
  zramSwap.enable = true;

  # ── Fonts ─────────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];

  # ── Nix ───────────────────────────────────────────────────────────────────
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store   = true;
      trusted-users         = [ "root" username ];
      substituters = [
        "https://cache.nixos.org"
        "https://claude-code.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
      ];
    };
    gc = {
      automatic = true;
      dates     = "weekly";
      options   = "--delete-older-than 30d";
    };
    optimise.automatic = true;
    # Pin registry so `nix run`, `nix shell` etc. use the same nixpkgs as the system
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];

  # ── Shell ─────────────────────────────────────────────────────────────────
  programs.zsh.enable = true;

  # ── User ──────────────────────────────────────────────────────────────────
  users.users.${username} = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "docker" "input" ];
    shell        = pkgs.zsh;
  };

  # GUI apps are managed by home-manager (home/desktop.nix + home/personal-apps.nix)

  time.timeZone      = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "26.05";
}
