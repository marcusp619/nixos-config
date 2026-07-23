{ config, pkgs, lib, inputs, username, ... }:
let
  # Upstream illogical-impulse ("ii") dotfiles, forked at
  # github:marcusp619/dots-hyprland. Deployed read-only: everything under
  # dots/.config/** is symlinked straight from the flake input rather than
  # copied, so updates are a flake.lock bump. Machine-specific overrides
  # live in hypr/custom/*.lua (Phase 2), which upstream's own hyprland.lua
  # only requires if the file exists.
  dotsConfig = "${inputs.dots-hyprland}/dots/.config";

  # Every package in sdata/uv/requirements.txt (ii's Python backend for
  # color generation, image analysis, etc.) already exists as a properly
  # built nixpkgs python3Packages derivation — including the ones with no
  # prebuilt PyPI wheels (pygobject3, pycairo, dbus-python, pywayland).
  # Building those from source via uv/pip hit real, known-hard NixOS
  # packaging problems (pywayland's setup.py hardcodes /usr/share/wayland/
  # wayland.xml, an FHS path that doesn't exist here) that nixpkgs has
  # already solved properly. Using nixpkgs' own builds instead of
  # rebuilding them at every home-manager activation is both more correct
  # and far more robust.
  illogicalImpulsePython = pkgs.python3.withPackages (ps: with ps; [
    pywayland
    pygobject3
    pycairo
    dbus-python
    pillow
    numpy
    opencv4 # closest match to requirements.txt's opencv-contrib-python;
            # if a contrib-only submodule import fails, that's the gap
    requests
    click
    loguru
    psutil
    cryptography
    google-auth
    setuptools-scm
    wheel
    build
    tqdm
    setproctitle
    packaging
    materialyoucolor
    kde-material-you-colors
    material-color-utilities
    libsass
  ]);

  # quickshell/ii as deployed, with the missing rounded-polygon-qmljs
  # submodule content copied into place. Confirmed by actually running
  # `qs -c ii`: without this, MaterialShape.qml (used throughout the bar)
  # fails to load with `module "qs.modules.common.widgets.shapes" is not
  # installed`. The submodule repo's root files map directly onto that
  # mount point (geometry/, shapes/, material-shapes.js).
  quickshellIi = pkgs.runCommand "quickshell-ii-merged" { } ''
    cp -r ${dotsConfig}/quickshell/ii $out
    chmod -R u+w $out
    rm -rf $out/modules/common/widgets/shapes
    cp -r ${inputs.rounded-polygon-qmljs} $out/modules/common/widgets/shapes
    chmod -R u+w $out/modules/common/widgets/shapes

    # services/Wallpapers.qml's own "extensions" list (which drives the
    # wallpaper-picker grid's nameFilters) has a literal "// TODO: add
    # videos" comment above it and only lists image extensions — so video
    # wallpapers work via switchwall.sh/mpvpaper, but never show up in the
    # picker to select in the first place. Patching in the same extensions
    # switchwall.sh's own is_video() already recognizes (mp4/webm/mkv/avi/
    # mov), so the picker actually surfaces them.
    substituteInPlace $out/services/Wallpapers.qml \
      --replace-fail \
        '"jpg", "jpeg", "png", "webp", "avif", "bmp", "svg"' \
        '"jpg", "jpeg", "png", "webp", "avif", "bmp", "svg", "mp4", "webm", "mkv", "avi", "mov"'
  '';
in
{
  # ── Hyprland: Lua config, ii's entrypoint ───────────────────────────────
  # package = null: installation is handled by programs.hyprland.enable in
  # hosts/desktop/configuration.nix, same as before.
  #
  # systemd.enable = false: home-manager's own Lua generator would otherwise
  # write xdg.configFile."hypr/hyprland.lua" itself (with just the
  # dbus-update-activation-environment startup hook), colliding with our own
  # xdg.configFile entry for that same path below. ii's execs.lua already
  # runs "dbus-update-activation-environment --all" on hyprland.start, so
  # nothing is lost; the extra hyprland-session.target home-manager would
  # add is also redundant here since hosts/desktop/configuration.nix already
  # runs Hyprland under UWSM (withUWSM = true), which provides its own
  # graphical-session.target wiring.
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    configType = "lua";
    systemd.enable = false;
  };

  # xdg-desktop-portal 1.17+ needs an explicit precedence order per
  # interface or it just warns and falls back to picking alphabetically.
  # Carried over from the old home/hyprland.nix, which this module
  # replaced — dropping it silently regressed this warning back in.
  xdg.portal.config = {
    hyprland.default = [ "hyprland" "gtk" ];
    common.default   = [ "gtk" ];
  };

  xdg.configFile = {
    "hypr/hyprland.lua".source = "${dotsConfig}/hypr/hyprland.lua";

    # hypr/hyprland/* individually, NOT as one directory symlink: matugen's
    # config.toml (confirmed by reading it) renders colors.lua from a
    # template on every wallpaper change, so that one file must stay a
    # real writable file rather than a nix-store symlink. Seeded once by
    # the activation script below; everything else here is static.
    "hypr/hyprland/env.lua".source = "${dotsConfig}/hypr/hyprland/env.lua";
    "hypr/hyprland/execs.lua".source = "${dotsConfig}/hypr/hyprland/execs.lua";
    "hypr/hyprland/general.lua".source = "${dotsConfig}/hypr/hyprland/general.lua";
    "hypr/hyprland/keybinds.lua".source = "${dotsConfig}/hypr/hyprland/keybinds.lua";
    "hypr/hyprland/rules.lua".source = "${dotsConfig}/hypr/hyprland/rules.lua";
    "hypr/hyprland/variables.lua".source = "${dotsConfig}/hypr/hyprland/variables.lua";
    "hypr/hyprland/lib".source = "${dotsConfig}/hypr/hyprland/lib";
    "hypr/hyprland/services".source = "${dotsConfig}/hypr/hyprland/services";
    "hypr/hyprland/scripts".source = "${dotsConfig}/hypr/hyprland/scripts";
    "hypr/hyprland/shellOverrides".source = "${dotsConfig}/hypr/hyprland/shellOverrides";

    # ── hypr/custom/*.lua: machine-specific overrides ─────────────────────
    # hyprland.lua only requires these if present, loaded after the
    # matching hyprland/*.lua default, so config = { input = {...} } keys
    # not already set upstream just add on top; keys ii already sets
    # (kb_layout, gaps, blur, etc.) are intentionally left alone.
    "hypr/custom/general.lua".text = ''
      -- Ultrawide's EDID "preferred" timing tops out below 240Hz, so pin
      -- the mode explicitly (this desktop only has the one display).
      hl.monitor({
          output = "",
          mode = "5120x1440@240",
          position = "auto",
          scale = 1
      })

      hl.config({
          input = {
              kb_options = "caps:escape"
          },
          general = {
              -- Hyprland 0.55.4 dwindle null-derefs in
              -- CDwindleAlgorithm::removeTarget during compositor shutdown
              -- (coredump-confirmed 2026-07-20); use master until upstream
              -- fixes the exit-path crash.
              layout = "master"
          }
      })
    '';

    "hypr/custom/env.lua".text = ''
      -- Carried over from the pre-ii Hyprland config; ii's own env.lua
      -- doesn't set these.
      hl.env("NIXOS_OZONE_WL", "1")
      hl.env("XCURSOR_THEME", "catppuccin-mocha-dark-cursors")
      hl.env("XCURSOR_SIZE", "24")
      hl.env("HYPRCURSOR_THEME", "catppuccin-mocha-dark-cursors")
      hl.env("HYPRCURSOR_SIZE", "24")
    '';

    "hypr/custom/variables.lua".text = ''
      -- Pin explicitly instead of ii's default launch_first_available.sh
      -- auto-detection, to match this desktop's actual app choices.
      terminal = "ghostty"
      fileManager = "nautilus"
    '';

    "hypr/custom/execs.lua".text = ''
      hl.on("hyprland.start", function()
          -- Plasma isn't running under the Hyprland session, so start the
          -- polkit agent Plasma would otherwise provide.
          hl.exec_cmd("hyprpolkitagent")
          -- Re-assert our cursor theme: ii's own execs.lua unconditionally
          -- runs "hyprctl setcursor Bibata-Modern-Classic 24" earlier in
          -- this same startup hook, so this must run after it to win.
          hl.exec_cmd("hyprctl setcursor catppuccin-mocha-dark-cursors 24")
      end)
    '';

    "hypr/custom/keybinds.lua".text = ''
      hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),
          { description = "Edit user keybinds" })
    '';

    "hypr/custom/rules.lua".text = ''
      -- Nothing machine-specific needed yet; ii's own rules.lua already
      -- covers the common cases.
    '';

    # ── hypridle / hyprlock ────────────────────────────────────────────────
    # ii's own hypridle.conf locks/unlocks through Quickshell's lock screen
    # (falling back to hyprlock if Quickshell isn't running) — kept as-is.
    # Only the listener timeouts are ours, carried over unchanged from the
    # pre-ii hypridle config (300s lock / 330s dpms off / 900s suspend).
    "hypr/hypridle.conf".text = ''
      $lock_cmd = hyprctl dispatch 'hl.dsp.global("quickshell:lock")' & pidof qs quickshell hyprlock || hyprlock
      $suspend_cmd = systemctl suspend || loginctl suspend

      general {
          lock_cmd = $lock_cmd
          before_sleep_cmd = loginctl lock-session
          after_sleep_cmd = hyprctl dispatch 'hl.dsp.global("quickshell:lockFocus")'
          inhibit_sleep = 3
      }

      listener {
          timeout = 300 # 5min
          on-timeout = loginctl lock-session
      }

      listener {
          timeout = 330 # 5.5min
          on-timeout = hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'
          on-resume = hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
      }

      listener {
          timeout = 900 # 15min
          on-timeout = $suspend_cmd
      }
    '';

    # hyprlock.conf itself is static; hyprlock/colors.conf is a second
    # matugen output (matugen/config.toml: [templates.hyprlock]) and is
    # seeded by the activation script below instead, same reasoning as
    # hyprland/colors.lua above.
    "hypr/hyprlock.conf".source = "${dotsConfig}/hypr/hyprlock.conf";
    "hypr/hyprlock/check-capslock.sh".source = "${dotsConfig}/hypr/hyprlock/check-capslock.sh";
    "hypr/hyprlock/status.sh".source = "${dotsConfig}/hypr/hyprlock/status.sh";

    # ── Quickshell shell ("ii") ────────────────────────────────────────────
    # Whole directory, read-only: matugen's only output paths that touch
    # Quickshell's data at all are under ~/.local/state/quickshell/user/
    # generated/**, outside this tree entirely, so there's no write
    # conflict here the way there is for hypr/hyprland and hypr/hyprlock.
    # Sourced from quickshellIi (merged with the shapes submodule above),
    # not straight from the fork.
    "quickshell/ii".source = quickshellIi;

    # ── fuzzel ───────────────────────────────────────────────────────────────
    # fuzzel_theme.ini is matugen's third output path
    # ([templates.fuzzel]) and is seeded by the activation script instead.
    "fuzzel/fuzzel.ini".source = "${dotsConfig}/fuzzel/fuzzel.ini";

    # ── matugen ──────────────────────────────────────────────────────────────
    # config.toml + templates/ are matugen's inputs, not its outputs —
    # matugen only ever reads these, so the whole directory is safe
    # read-only.
    "matugen".source = "${dotsConfig}/matugen";

    # ── Kvantum theme assets ─────────────────────────────────────────────────
    # Static resource bundles; kvantum.kvconfig itself (the "which theme is
    # active" pointer) is deliberately left unmanaged rather than pulled in
    # read-only, for the same class of reason as the matugen outputs above.
    "Kvantum/Colloid".source = "${dotsConfig}/Kvantum/Colloid";
    "Kvantum/MaterialAdw".source = "${dotsConfig}/Kvantum/MaterialAdw";
  };

  # ── Seed matugen's output files on first run only ───────────────────────
  # matugen writes hypr/hyprland/colors.lua, hypr/hyprlock/colors.conf, and
  # fuzzel/fuzzel_theme.ini at runtime (confirmed via matugen/config.toml's
  # [templates.*] output_path entries) whenever the wallpaper changes.
  # Those paths can't be xdg.configFile sources (would be read-only
  # nix-store symlinks matugen can't overwrite), but hyprland.lua requires
  # hyprland.colors unconditionally, so something has to exist there before
  # the very first matugen run. This copies upstream's static defaults in
  # only if the real file isn't there yet — never overwrites anything
  # matugen (or you) has since written.
  #
  # hypr/custom/scripts/__restore_video_wallpaper.sh is the same class of
  # problem from a different feature: switchwall.sh (video wallpaper
  # support) writes a regenerated version of this script into place
  # whenever you pick a video wallpaper (confirmed by reading its
  # create_restore_script function), and execs.lua calls it unconditionally
  # on every Hyprland start. Seeded here too so that directory/file exist
  # before the first video wallpaper pick, executable since it's a script.
  home.activation.dotsHyprlandSeedMatugenOutputs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    seed() {
      if [[ ! -e "$HOME/.config/$1" ]]; then
        $DRY_RUN_CMD install -D -m"$3" "$2" "$HOME/.config/$1"
      fi
    }
    seed hypr/hyprland/colors.lua "${dotsConfig}/hypr/hyprland/colors.lua" 644
    seed hypr/hyprlock/colors.conf "${dotsConfig}/hypr/hyprlock/colors.conf" 644
    seed fuzzel/fuzzel_theme.ini "${dotsConfig}/fuzzel/fuzzel_theme.ini" 644
    seed hypr/custom/scripts/__restore_video_wallpaper.sh "${dotsConfig}/hypr/custom/scripts/__restore_video_wallpaper.sh" 755
  '';

  # ── Python "venv" for ii's color/image helper scripts ───────────────────
  # env.lua points ILLOGICAL_IMPULSE_VIRTUAL_ENV at ~/.local/state/
  # quickshell/.venv (confirmed by reading hypr/hyprland/env.lua), and the
  # venv-wrapper scripts under quickshell/ii/scripts/** do exactly:
  #   source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate
  #   "$SCRIPT_DIR/whatever.py" "$@"
  #   deactivate
  # A real `uv`/`venv`-created virtualenv isn't necessary to satisfy that —
  # it only needs a bin/activate that puts a working, fully-populated
  # python3 on PATH, and bin/deactivate's counterpart. This fakes exactly
  # that shape around illogicalImpulsePython above: fully declarative, no
  # activation-time builds, nothing to go stale or fail at switch time.
  home.file = {
    ".local/state/quickshell/.venv/bin/python3".source = "${illogicalImpulsePython}/bin/python3";
    ".local/state/quickshell/.venv/bin/python".source = "${illogicalImpulsePython}/bin/python3";
    ".local/state/quickshell/.venv/bin/activate".text = ''
      VIRTUAL_ENV="$HOME/.local/state/quickshell/.venv"
      export VIRTUAL_ENV
      _OLD_VIRTUAL_PATH="$PATH"
      PATH="$VIRTUAL_ENV/bin:$PATH"
      export PATH
      deactivate () {
          PATH="$_OLD_VIRTUAL_PATH"
          export PATH
          unset _OLD_VIRTUAL_PATH
          unset VIRTUAL_ENV
          unset -f deactivate
      }
    '';
  };

  # ── Cursor ───────────────────────────────────────────────────────────────
  home.pointerCursor = {
    name = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size = 24;
    gtk.enable = true;
    hyprcursor.enable = true;
  };

  # ── Packages ─────────────────────────────────────────────────────────────
  # Mirrors upstream's sdata/deps-info.md, using nixpkgs names confirmed to
  # exist on the nixos-26.05 channel this flake pins. Anything upstream
  # marks "not explicitly used" is left out; add back only if something
  # actually breaks without it.
  home.packages = with pkgs; [
    # Shell / theming engines
    quickshell
    matugen
    fuzzel

    # QML modules quickshell/ii needs at runtime beyond what the
    # `quickshell` package itself bundles — found by actually running
    # `qs -c ii` and reading the "module X is not installed" errors one at
    # a time, fixing each, and re-running until it reported "Configuration
    # Loaded" with nothing but expected first-run warnings. All of these
    # exist in the store already as transitive Plasma6 build deps, but
    # weren't linked into any profile's QML import path until added here.
    kdePackages.qt5compat # Qt5Compat.GraphicalEffects (ReloadPopup.qml)
    qt6.qtpositioning # QtPositioning (Weather.qml)
    # plain kdePackages.kirigami resolves to a contentless wrapper
    # (nix-support/propagated-build-inputs only, no actual QML); the real
    # org.kde.kirigami QML files are in its .unwrapped output.
    kdePackages.kirigami.unwrapped
    kdePackages.syntax-highlighting # org.kde.syntaxhighlighting (AiChat's code blocks)

    # Audio
    cava
    pavucontrol
    playerctl

    # Backlight / display
    brightnessctl
    ddcutil

    # Basic CLI deps used throughout ii's Hyprland + Quickshell config
    bc
    curl
    wget
    ripgrep
    jq
    xdg-user-dirs

    # Screenshot/clipboard: ii's own keybinds.lua and execs.lua call these
    # directly (grim/slurp for screenshots, wl-copy/wl-paste for
    # clipboard). swappy and nautilus carried over from the pre-ii config.
    grim
    slurp
    wl-clipboard
    cliphist
    swappy
    nautilus
    hyprpolkitagent

    # GTK/Qt theming
    adw-gtk3
    darkly
    kdePackages.qtstyleplugin-kvantum

    # Fonts (in addition to nerd-fonts.jetbrains-mono already installed at
    # the NixOS level in hosts/desktop/configuration.nix)
    google-fonts # Readex Pro, Rubik, Space Grotesk
    material-symbols
    twemoji-color-font

    # Hyprland ecosystem
    hyprsunset
    hypridle
    hyprlock
    hyprpicker
    wlogout

    # Video wallpapers: switchwall.sh (quickshell/ii/scripts/colors/) shells
    # out to mpvpaper for mp4/webm/mkv/avi/mov wallpapers, and checks for
    # ffmpeg to generate their thumbnails in the wallpaper picker.
    mpvpaper
    ffmpeg

    # KDE integration ii's Quickshell config shells out to
    gnome-keyring

    # Screen capture / OCR / recording
    hyprshot
    tesseract
    wf-recorder

    # Misc toolkit
    upower
    wtype
    ydotool
    imagemagick
    songrec
    translate-shell
    libqalculate
  ];
}
