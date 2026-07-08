{ config, pkgs, inputs, username, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # ── Boot ─────────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Intel graphics tweaks for MBP 2017
  boot.kernelParams = [ "i915.enable_fbc=1" "i915.enable_psr=0" ];

  # Broadcom WiFi + Apple CS8409 audio
  boot.extraModulePackages = [
    config.boot.kernelPackages.broadcom_sta
    (config.boot.kernelPackages.callPackage ./pkgs/snd_hda_macbookpro.nix {})
  ];
  boot.kernelModules          = [ "wl" "apple-ib-tb" "apple-ibridge" "snd_hda_codec_cs8409" ];
  boot.blacklistedKernelModules = [ "b43" "bcma" "ssb" ];
  boot.extraModprobeConfig    = ''
    options cfg80211 ieee80211_regdom=US
    options apple-ib-tb fnmode=2
  '';

  # ── Networking ────────────────────────────────────────────────────────────
  networking.hostName            = "personal-macbook";
  networking.networkmanager.enable = true;
  hardware.wirelessRegulatoryDatabase = true;

  # ── Hardware ──────────────────────────────────────────────────────────────
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.linux-firmware ];

  # Intel GPU
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
  ];

  # ── Audio (PipeWire) ──────────────────────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable      = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };

  # ── Desktop (GNOME + LightDM) ─────────────────────────────────────────────
  services.xserver.enable                        = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.desktopManager.gnome.enable           = true;
  services.xserver.xkb = {
    layout  = "us";
    options = "caps:escape";
  };

  # ── Touch Bar ─────────────────────────────────────────────────────────────
  systemd.user.services.tiny-dfr = {
    description = "Tiny Apple Touch Bar Display Manager";
    after    = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.tiny-dfr}/bin/tiny-dfr";
      Restart   = "on-failure";
    };
  };

  # ── Services ──────────────────────────────────────────────────────────────
  services.openssh.enable  = true;
  services.tailscale.enable = true;
  services.printing.enable = true;
  virtualisation.docker.enable = true;

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
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-6.18.22"
    "libsoup-2.74.3"
  ];

  # ── Shell ─────────────────────────────────────────────────────────────────
  programs.zsh.enable = true;

  # ── User ──────────────────────────────────────────────────────────────────
  users.users.${username} = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "docker" ];
    shell        = pkgs.zsh;
  };

  # ── Gaming ────────────────────────────────────────────────────────────────
  programs.steam.enable = true;

  # GUI apps shared with desktop are managed by home-manager (home/personal-apps.nix)
  environment.systemPackages = with pkgs; [
    appimage-run
    tiny-dfr
    alsa-utils
    # Tauri / GTK build deps
    webkitgtk_4_1
    libsoup_2_4
    gtk3
  ];

  time.timeZone      = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "25.11";
}
