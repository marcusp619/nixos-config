{ config, pkgs, lib, inputs, username, ... }:
let
  cursorName = "catppuccin-mocha-dark-cursors";
  cursorSize = 24;

  rasi = config.lib.formats.rasi.mkLiteral;

  # Nix-level variables instead of hyprlang $vars: Hyprland's Lua config
  # (which home-manager now generates) has no $variable concept, and attrs
  # like "$mod" render as invalid Lua (hl.$mod(...)).
  mod         = "SUPER";
  terminal    = "ghostty";
  fileManager = "nautilus";
  menu        = "rofi -show drun";

  workspaceBinds = lib.concatMap (i: [
    "${mod}, ${toString i}, workspace, ${toString i}"
    "${mod} SHIFT, ${toString i}, movetoworkspace, ${toString i}"
  ]) (lib.range 1 9);
in
{
  home.packages = with pkgs; [
    grim
    slurp
    swappy
    wl-clipboard
    playerctl
    wlogout
    papirus-icon-theme
  ];

  # ── Hyprland itself ────────────────────────────────────────────────────────
  # package = null: installation/wrapping is handled by programs.hyprland.enable
  # in hosts/desktop/configuration.nix; home-manager only generates the config.
  wayland.windowManager.hyprland = {
    enable  = true;
    package = null;

    # stateVersion >= 26.05 flipped the default to "lua", which renders this
    # hyprlang-style settings tree as broken Lua (hl.exec-once(...), etc.).
    # Pin hyprlang; migrating to the Lua API is a separate project.
    configType = "hyprlang";

    settings = {
      monitor = [ ",5120x1440@240,auto,1" ];

      env = [
        "XCURSOR_THEME,${cursorName}"
        "XCURSOR_SIZE,${toString cursorSize}"
        "HYPRCURSOR_THEME,${cursorName}"
        "HYPRCURSOR_SIZE,${toString cursorSize}"
        "QT_QPA_PLATFORMTHEME,gtk3"
        "NIXOS_OZONE_WL,1"
      ];

      input = {
        kb_layout   = "us";
        kb_options  = "caps:escape";
        follow_mouse = 1;
        sensitivity = 0;
      };

      general = {
        gaps_in     = 5;
        gaps_out    = 10;
        border_size = 2;
        "col.active_border"   = "rgba(cba6f7ee) rgba(89b4faee) 45deg";
        "col.inactive_border" = "rgba(45475aaa)";
        # Temporary workaround: dwindle's calculateWorkspace() null-derefs in
        # CDwindleAlgorithm::removeTarget during compositor shutdown cleanup
        # (segfault confirmed via coredumpctl on 2026-07-20, Hyprland 0.55.4).
        # Switch back to dwindle once upstream fixes the exit-path crash.
        layout        = "master";
        resize_on_border = true;
        # Tearing allowed (opt-in per window below) to keep input latency low
        # for fullscreen games while streaming via Sunshine.
        allow_tearing = true;
      };

      decoration = {
        rounding = 8;
        active_opacity   = 1.0;
        inactive_opacity = 0.95;
        # Hyprland 0.45 moved shadow_* / col.shadow into a nested shadow block.
        shadow = {
          enabled = true;
          range = 20;
          render_power = 3;
          color = "rgba(11111bee)";
        };
        blur = {
          enabled  = true;
          size     = 6;
          passes   = 2;
          vibrancy = 0.1696;
        };
      };

      animations = {
        enabled = true;
        bezier = [ "overshot, 0.05, 0.9, 0.1, 1.0" ];
        animation = [
          "windows, 1, 4, overshot, slide"
          "windowsOut, 1, 4, default, popin 80%"
          "border, 1, 6, default"
          "fade, 1, 4, default"
          "workspaces, 1, 5, overshot, slide"
        ];
      };

      dwindle = {
        preserve_split = true;
      };

      misc = {
        disable_hyprland_logo    = true;
        disable_splash_rendering = true;
        # vfr removed — option no longer exists in Hyprland 0.55+
      };

      # windowrule/layerrule have no hyprlang syntax as of Hyprland 0.55 —
      # they only exist via the new Lua API (hl.window_rule()). Dropped here
      # until the Lua config migration; previously covered nautilus file
      # dialogs auto-floating and tearing/immediate for Steam games.

      "exec-once" = [ "hyprpolkitagent" ];

      bind = [
        "${mod}, Return, exec, ${terminal}"
        "${mod}, Q, killactive"
        "${mod} SHIFT, Q, exit"
        "${mod}, D, exec, ${menu}"
        "${mod}, E, exec, ${fileManager}"
        "${mod}, V, exec, cliphist list | rofi -dmenu -p clipboard | cliphist decode | wl-copy"
        "${mod}, F, togglefloating"
        "${mod}, P, pseudo"
        # Hyprland 0.54 removed the standalone togglesplit dispatcher in favor of layoutmsg.
        "${mod}, J, layoutmsg, togglesplit"
        "${mod}, L, exec, hyprlock"
        "${mod}, Escape, exec, wlogout"
        ", Print, exec, grim -g \"$(slurp)\" - | swappy -f -"
        "${mod}, Print, exec, grim - | swappy -f -"
      ] ++ workspaceBinds;

      bindm = [
        "${mod}, mouse:272, movewindow"
        "${mod}, mouse:273, resizewindow"
      ];

      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ];

      bindl = [
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPrev, exec, playerctl previous"
      ];
    };
  };

  # ── Idle / lock ──────────────────────────────────────────────────────────
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd         = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd  = "hyprctl dispatch dpms on";
      };
      listener = [
        { timeout = 300; "on-timeout" = "loginctl lock-session"; }
        { timeout = 330; "on-timeout" = "hyprctl dispatch dpms off"; "on-resume" = "hyprctl dispatch dpms on"; }
        { timeout = 900; "on-timeout" = "systemctl suspend"; }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      background = [{
        path  = "screenshot";
        blur_passes = 2;
        blur_size   = 4;
        color = "rgba(1e1e2eee)";
      }];
      "input-field" = [{
        size = "300, 50";
        outline_thickness = 2;
        dots_center = true;
        "col.outer_border" = "rgb(cba6f7)";
        "col.inner_color"  = "rgb(1e1e2e)";
        "col.font_color"   = "rgb(cdd6f4)";
        "col.check_color"  = "rgb(a6e3a1)";
        "col.fail_color"   = "rgb(f38ba8)";
        placeholder_text = "Password...";
        fade_on_empty = false;
        position = "0, -20";
        halign = "center";
        valign = "center";
      }];
      label = [
        {
          text = "cmd[update:1000] date +\"%H:%M:%S\"";
          font_size = 64;
          color = "rgb(cdd6f4)";
          position = "0, 200";
          halign = "center";
          valign = "center";
        }
        {
          text = "cmd[update:60000] date +\"%A, %B %d\"";
          font_size = 20;
          color = "rgb(bac2de)";
          position = "0, 120";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  # ── Wallpaper ────────────────────────────────────────────────────────────
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      preload  = [ "${pkgs.nixos-artwork.wallpapers.catppuccin-mocha.gnomeFilePath}" ];
      wallpaper = [ ",${pkgs.nixos-artwork.wallpapers.catppuccin-mocha.gnomeFilePath}" ];
    };
  };

  # ── Clipboard history ────────────────────────────────────────────────────
  services.cliphist.enable = true;

  # home-manager tracks xdg-desktop-portal config separately from the NixOS
  # system module set in hosts/desktop/configuration.nix; both need it.
  xdg.portal.config = {
    hyprland.default = [ "hyprland" "gtk" ];
    common.default   = [ "gtk" ];
  };

  # ── Launcher ─────────────────────────────────────────────────────────────
  programs.rofi = {
    enable = true;
    # rofi-wayland was merged into rofi upstream; the default package is
    # already Wayland-native.
    font = "JetBrainsMono Nerd Font 12";
    theme = {
      "*" = {
        background        = rasi "#1e1e2ee6";
        "background-alt"  = rasi "#313244";
        foreground        = rasi "#cdd6f4";
        selected          = rasi "#cba6f7";
        active            = rasi "#a6e3a1";
        urgent            = rasi "#f38ba8";
      };
      window = {
        transparency = "real";
        "background-color" = rasi "@background";
        border = 2;
        "border-color" = rasi "@selected";
        "border-radius" = 12;
        width = 480;
      };
      mainbox.children = map rasi [ "inputbar" "listview" ];
      inputbar = {
        children = map rasi [ "prompt" "entry" ];
        padding = 12;
        "background-color" = rasi "@background-alt";
        "border-radius" = 8;
      };
      entry.placeholder = "Search...";
      listview = {
        lines = 8;
        padding = "8px 0px";
        scrollbar = false;
      };
      element = {
        padding = "8px 12px";
        "border-radius" = 8;
      };
      "element selected" = {
        "background-color" = rasi "@selected";
        "text-color" = rasi "@background";
      };
    };
  };

  # ── Notifications ────────────────────────────────────────────────────────
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      "control-center-layer" = "overlay";
      "control-center-width" = 400;
      "notification-window-width" = 400;
      "notification-icon-size" = 48;
      timeout = 6;
      "timeout-low" = 3;
      "timeout-critical" = 0;
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
      }
      .notification-row, .control-center {
        background: transparent;
      }
      .notification-background, .control-center-list {
        background: #1e1e2ee6;
        border: 1px solid #cba6f7;
        border-radius: 12px;
        color: #cdd6f4;
      }
      .notification-content { padding: 8px; }
      .close-button {
        background: #313244;
        color: #cdd6f4;
        border-radius: 8px;
      }
      .close-button:hover { background: #f38ba8; color: #1e1e2e; }
      widget-title > label { color: #cba6f7; font-weight: bold; }
      .body { color: #cdd6f4; }
    '';
  };

  # ── Status bar ───────────────────────────────────────────────────────────
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = [{
      layer  = "top";
      position = "top";
      height = 32;
      "modules-left"   = [ "hyprland/workspaces" "hyprland/window" ];
      "modules-center" = [ "clock" ];
      "modules-right"  = [ "pulseaudio" "network" "cpu" "memory" "tray" "custom/power" ];

      "hyprland/workspaces" = {
        format = "{icon}";
        "on-click" = "activate";
      };
      clock.format = "{:%a %b %d  %H:%M}";
      pulseaudio = {
        format = "{icon} {volume}%";
        "format-muted" = "  muted";
        "format-icons" = [ "" "" "" ];
        "on-click" = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };
      network = {
        "format-wifi" = " {essid}";
        "format-ethernet" = " {ifname}";
        "format-disconnected" = "⚠ disconnected";
      };
      cpu.format = " {usage}%";
      memory.format = " {used:0.1f}G";
      tray.spacing = 10;
      "custom/power" = {
        format = "⏻";
        tooltip = false;
        "on-click" = "wlogout";
      };
    }];
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        min-height: 0;
      }
      window#waybar {
        background: #1e1e2ee6;
        color: #cdd6f4;
      }
      #workspaces button {
        padding: 0 8px;
        color: #a6adc8;
      }
      #workspaces button.active {
        color: #cba6f7;
        border-bottom: 2px solid #cba6f7;
      }
      #clock, #pulseaudio, #network, #cpu, #memory, #tray, #custom-power, #window {
        padding: 0 10px;
      }
      #custom-power { color: #f38ba8; }
    '';
  };

  # ── wlogout (power menu) ─────────────────────────────────────────────────
  xdg.configFile."wlogout/layout.json".text = builtins.toJSON [
    { label = "lock";     action = "hyprlock";              text = "Lock";     keybind = "l"; }
    { label = "logout";   action = "hyprctl dispatch exit"; text = "Logout";   keybind = "e"; }
    { label = "suspend";  action = "systemctl suspend";     text = "Suspend";  keybind = "s"; }
    { label = "reboot";   action = "systemctl reboot";      text = "Reboot";   keybind = "r"; }
    { label = "shutdown"; action = "systemctl poweroff";    text = "Shutdown"; keybind = "p"; }
  ];
  xdg.configFile."wlogout/style.css".text = ''
    * {
      font-family: "JetBrainsMono Nerd Font";
      background-image: none;
    }
    window {
      background: rgba(30, 30, 46, 0.85);
    }
    button {
      color: #cdd6f4;
      background: #313244;
      border: 2px solid #45475a;
      border-radius: 12px;
      margin: 12px;
      padding: 24px;
    }
    button:hover, button:focus {
      border-color: #cba6f7;
      background: #45475a;
    }
  '';

  # ── GTK / Qt / cursor theming ────────────────────────────────────────────
  home.pointerCursor = {
    name = cursorName;
    package = pkgs.catppuccin-cursors.mochaDark;
    size = cursorSize;
    gtk.enable = true;
    hyprcursor.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Mocha-Standard-Mauve";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        accents = [ "mauve" ];
      };
    };
    # stateVersion >= 26.05 flipped gtk4.theme's default from "follow
    # gtk.theme" to null; pin it so GTK4 apps keep the catppuccin theme.
    gtk4.theme = config.gtk.theme;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };
}
