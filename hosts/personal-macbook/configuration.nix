{ config, pkgs, lib, inputs, username, ... }:
let
  # The custom CS8409 module lands in extra/ as a symlink to another store path.
  # depmod -b doesn't follow out-of-tree symlinks, so the module never appears in
  # modules.dep and modprobe silently loads the mainline .ko.xz instead.
  # Grab the exact store path so we can insmod it directly via an install override.
  cs8409Pkg = config.boot.kernelPackages.callPackage ./pkgs/snd_hda_macbookpro.nix {};
  cs8409Ko  = "${cs8409Pkg}/lib/modules/${config.boot.kernelPackages.kernel.modDirVersion}/extra/snd-hda-codec-cs8409.ko";
in
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

    # Force-load the Apple-specific CS8409 driver instead of the mainline one.
    # modprobe's 'install' directive intercepts all loads of snd_hda_codec_cs8409
    # (including alias-based loads from the HDA framework) and runs this command
    # instead.  We first load the dependency chain via the normal modprobe path,
    # then insmod the custom .ko directly so depmod ordering is irrelevant.
    install snd_hda_codec_cs8409 ${pkgs.kmod}/bin/modprobe --ignore-install snd-hda-codec-generic && ${pkgs.kmod}/bin/insmod ${cs8409Ko}
  '';

  # ── Networking ────────────────────────────────────────────────────────────
  networking.hostName            = "personal-macbook";
  networking.networkmanager.enable = true;
  hardware.wirelessRegulatoryDatabase = true;

  # ── Hardware ──────────────────────────────────────────────────────────────
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.linux-firmware ];

  # Intel iGPU (primary); AMD dGPU (amdgpu) is loaded by the kernel automatically
  # but left in power-save / unused by the desktop session — Intel handles display.
  # If you ever want to route rendering to the AMD card, set DRI_PRIME=1.
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

  # Speech synthesis (accessibility / TTS)
  services.speechd.enable = true;

  # ── Desktop (GNOME + LightDM) ─────────────────────────────────────────────
  services.xserver.enable                        = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.desktopManager.gnome.enable           = true;
  services.xserver.xkb = {
    layout  = "us";
    options = "caps:escape";
  };

  # Libinput — touchpad gestures and natural scrolling
  services.libinput.enable = true;

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

  # ── Power management (old Intel + hybrid GPU laptop) ──────────────────────
  services.thermald.enable          = true;  # Intel thermal management daemon
  services.power-profiles-daemon.enable = true;  # GNOME power-profiles integration
  powerManagement.enable            = true;  # systemd sleep/suspend integration

  # ── Services ──────────────────────────────────────────────────────────────
  services.openssh.enable   = true;
  services.tailscale.enable = true;
  services.printing.enable  = true;
  virtualisation.docker.enable = true;

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
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  nixpkgs.config.allowUnfree = true;
  # Allow by name, not exact version: these version strings drift with every
  # kernel/nixpkgs bump and were breaking the nightly flake.lock CI.
  # broadcom-sta = this MacBook's wifi (no alternative); electron = EOL
  # version pulled by bitwarden-desktop; libsoup = Tauri build dep.
  nixpkgs.config.allowInsecurePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "broadcom-sta" "electron" "libsoup" ];

  # ── Shell ─────────────────────────────────────────────────────────────────
  programs.zsh.enable = true;

  # ── User ──────────────────────────────────────────────────────────────────
  users.users.${username} = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "docker" ];
    shell        = pkgs.zsh;
  };

  # ── Auto-upgrade ──────────────────────────────────────────────────────────
  system.autoUpgrade = {
    enable = true;
    flake  = "github:marcusp619/nixos-config#personal-macbook";
    dates  = "daily";
  };

  # System packages for this host (GUI apps managed by home-manager)
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
