{ ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };

  brightnessctl = lib.getExe pkgs.brightnessctl;
  dbus-update = pkgs.dbus + /bin/dbus-update-activation-environment;
  fuzzel = lib.getExe config.programs.fuzzel.package;
  kitty = lib.getExe config.programs.kitty.package;
  loginctl = osConfig.systemd.package + /bin/loginctl;
  niri = lib.getExe config.programs.niri.package;
  nushell = lib.getExe config.programs.nushell.package;
  playerctl = config.services.playerctld.package + /bin/playerctl;
  swaylock = lib.getExe config.programs.swaylock.package;
  systemctl = osConfig.systemd.package + /bin/systemctl;
  wpctl = osConfig.services.pipewire.wireplumber.package + /bin/wpctl;
  xdg-open = pkgs.xdg-utils + /bin/xdg-open;

  askpass = let
    pkg = pkgs.writeShellApplication {
      name = "fuzzel-askpass";
      text = ''
        exec ${fuzzel} \
          --font=monospace \
          --prompt="󰣀 " \
          --password \
          --lines=0 \
          --dmenu
      '';
    };
  in lib.getExe pkg;
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  home.packages = with pkgs; [
    calibre
    fractal
    inkscape
    jellyfin-mpv-shim
    keepassxc
    man-pages
    man-pages-posix
    restic
    simple-scan
  ];

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        prompt = "❯ ";
      };
    };
  };

  programs.niri.settings = {
    prefer-no-csd = true;
    hotkey-overlay.skip-at-startup = true;
    screenshot-path = "~/tmp/%Y-%m-%d %H:%M:%S.png";

    input = {
      keyboard = {
        xkb = with config.home.keyboard; {
          inherit layout;
          options = options |> lib.concatStringsSep ",";
        };
      };

      focus-follows-mouse.enable = true;

      touchpad = {
        dwt = true;
        dwtp = true;
      };
    };

    outputs = {
      eDP-1 = {
        scale = 1;
        variable-refresh-rate = true;
      };

      DP-6 = {
        mode = { width = 5120; height = 2160; };
        scale = 1;
        position = { x = 0; y = 0; };
        variable-refresh-rate = true;
      };
    };

    layout = {
      border.enable = lib.mkForce false;
      focus-ring = {
        enable = true;
        width = 1;

        active = {
          color = config.lib.stylix.colors.withHashtag.base0D;
        };

        inactive = {
          color = config.lib.stylix.colors.withHashtag.base03;
        };
      };

      default-column-width.proportion = 1. / 3.;

      gaps = 5;

      preset-column-widths = [
        { proportion = 1. / 3.; }
        { proportion = 1. / 2.; }
        { proportion = 2. / 3.; }
      ];
    };

    window-rules = [
      {
        clip-to-geometry = true;
        geometry-corner-radius = {
          top-left = 4.0;
          top-right = 4.0;
          bottom-left = 4.0;
          bottom-right = 4.0;
        };
      }
      {
        matches = [
          { app-id = ''^notifications$''; }
          { app-id = ''^mpv$''; }
        ];

        block-out-from = "screencast";
      }
      {
        matches = [
          { app-id = ''^firefox\.private$''; }
          { app-id = ''^kitty\.private$''; }
          { app-id = ''^org\.gnome\.Fractal$''; }
          { app-id = ''^org\.keepassxc\.KeePassXC$''; }
          { app-id = ''^signal$''; }
        ];

        block-out-from = "screen-capture";
      }
    ];

    binds = with config.lib.niri.actions; {
      # Application spawning
      "Mod+Return".action = spawn [ kitty ];
      "Mod+Shift+Return".action = spawn [ kitty "--app-id" "private" nushell "--no-history" ];
      "Mod+E".action = spawn [ fuzzel ];

      # Window & column focus
      "Mod+Left".action = focus-column-left;
      "Mod+Down".action = focus-window-down;
      "Mod+Up".action = focus-window-up;
      "Mod+Right".action = focus-column-right;
      "Mod+R".action = focus-column-left;
      "Mod+N".action = focus-window-down;
      "Mod+T".action = focus-window-up;
      "Mod+H".action = focus-column-right;

      # Window & column movement
      "Mod+Ctrl+Left".action = move-column-left;
      "Mod+Ctrl+Down".action = move-window-down;
      "Mod+Ctrl+Up".action = move-window-up;
      "Mod+Ctrl+Right".action = move-column-right;
      "Mod+Ctrl+R".action = move-column-left;
      "Mod+Ctrl+N".action = move-window-down;
      "Mod+Ctrl+T".action = move-window-up;
      "Mod+Ctrl+H".action = move-column-right;

      # Consume & expel windows to / from columns
      "Mod+G".action = consume-window-into-column;
      "Mod+B".action = expel-window-from-column;
      "Mod+Slash".action = consume-or-expel-window-left;
      "Mod+At".action = consume-or-expel-window-right;

      # Focus & move column front / back
      "Mod+Home".action = focus-column-first;
      "Mod+End".action = focus-column-last;
      "Mod+Ctrl+Home".action = move-column-to-first;
      "Mod+Ctrl+End".action = move-column-to-last;

      # Monitor focus
      "Mod+Shift+Left".action = focus-monitor-left;
      "Mod+Shift+Down".action = focus-monitor-down;
      "Mod+Shift+Up".action = focus-monitor-up;
      "Mod+Shift+Right".action = focus-monitor-right;
      "Mod+Shift+R".action = focus-monitor-left;
      "Mod+Shift+N".action = focus-monitor-down;
      "Mod+Shift+T".action = focus-monitor-up;
      "Mod+Shift+H".action = focus-monitor-right;

      # Moving columns between monitors
      "Mod+Ctrl+Shift+Left".action = move-column-to-monitor-left;
      "Mod+Ctrl+Shift+Down".action = move-column-to-monitor-down;
      "Mod+Ctrl+Shift+Up".action = move-column-to-monitor-up;
      "Mod+Ctrl+Shift+Right".action = move-column-to-monitor-right;
      "Mod+Ctrl+Shift+R".action = move-column-to-monitor-left;
      "Mod+Ctrl+Shift+N".action = move-column-to-monitor-down;
      "Mod+Ctrl+Shift+T".action = move-column-to-monitor-up;
      "Mod+Ctrl+Shift+H".action = move-column-to-monitor-right;

      # Workspace focus
      "Mod+Page_Down".action = focus-workspace-down;
      "Mod+Page_Up".action = focus-workspace-up;
      "Mod+L".action = focus-workspace-down;
      "Mod+M".action = focus-workspace-up;

      # Moving columns between workspaces
      "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
      "Mod+Ctrl+Page_Up".action = move-column-to-workspace-up;
      "Mod+Ctrl+L".action = move-column-to-workspace-down;
      "Mod+Ctrl+M".action = move-column-to-workspace-up;

      # Workspace movement
      "Mod+Shift+Page_Down".action = move-workspace-down;
      "Mod+Shift+Page_Up".action = move-workspace-up;
      "Mod+Shift+L".action = move-workspace-down;
      "Mod+Shift+M".action = move-workspace-up;

      # Mouse wheel for workspace focus & movement
      "Mod+WheelScrollDown" = { cooldown-ms = 150; action = focus-workspace-down; };
      "Mod+WheelScrollUp" = { cooldown-ms = 150; action = focus-workspace-up; };
      "Mod+Shift+WheelScrollDown" = { cooldown-ms = 150; action = focus-column-right; };
      "Mod+Shift+WheelScrollUp" = { cooldown-ms = 150; action = focus-column-left; };
      "Mod+Ctrl+WheelScrollDown" = { cooldown-ms = 150; action = move-column-to-workspace-down; };
      "Mod+Ctrl+WheelScrollUp" = { cooldown-ms = 150; action = move-column-to-workspace-up; };
      "Mod+Ctrl+Shift+WheelScrollDown" = { cooldown-ms = 150; action = move-column-right; };
      "Mod+Ctrl+Shift+WheelScrollUp" = { cooldown-ms = 150; action = move-column-left; };

      # Column & window size (rough)
      "Mod+Y".action = switch-preset-column-width;
      "Mod+Shift+Y".action = reset-window-height;
      "Mod+I".action = maximize-column;
      "Mod+Shift+I".action = fullscreen-window;

      # Column & window size (fine)
      "Mod+Exclam".action = set-column-width "-10%";
      "Mod+Numbersign".action = set-column-width "-10%";
      "Mod+Shift+Exclam".action = set-window-height "-10%";
      "Mod+Shift+Numbersign".action = set-window-height "+10%";

      # Screenshots
      "Mod+Print".action = screenshot;
      "Mod+Ctrl+Print".action = screenshot-window;
      "Mod+Shift+Print".action = screenshot-screen;

      # Window & compositor termination
      "Mod+Shift+K".action = close-window;
      "Mod+Shift+U".action = quit;
      "Mod+Shift+C".action = power-off-monitors;

      # Session lock
      "Mod+Escape".action = spawn [ loginctl "lock-session" ];

      # Multimedia keys
      XF86Explorer.action = spawn [ xdg-open "https:" ];
    } // lib.mapAttrs (n: v: v // { allow-when-locked = true; }) {
      XF86MonBrightnessUp.action = spawn [ brightnessctl "-e" "set" "+5%" ];
      XF86MonBrightnessDown.action = spawn [ brightnessctl "-e" "set" "5%-" ];
      XF86AudioRaiseVolume.action = spawn [ wpctl "set-volume" "@DEFAULT_AUDIO_SINK@" "+2dB" ];
      XF86AudioLowerVolume.action = spawn [ wpctl "set-volume" "@DEFAULT_AUDIO_SINK@" "-2dB" ];
      XF86AudioMute.action = spawn [ wpctl "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
      XF86AudioMicMute.action = spawn [ wpctl "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle" ];
      XF86AudioNext.action = spawn [ playerctl "next" ];
      XF86AudioPrev.action = spawn [ playerctl "previous" ];
      XF86AudioPlay.action = spawn [ playerctl "play" ];
      XF86AudioStop.action = spawn [ playerctl "pause" ];
    };

    environment = {
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      NIXOS_OZONE_WL = "1";
      SSH_ASKPASS = askpass;
      SSH_ASKPASS_REQUIRE = "force";
      TERMINAL = kitty;
    };
  };

  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      screenshots = true;
      effect-blur = "5x3";
      grace = 2;
    };
  };

  services.mako = {
    enable = true;
    defaultTimeout = 5000;
  };

  services.playerctld.enable = true;

  services.swayidle = {
    enable = true;
    events = [
      { event = "lock"; command = "${swaylock} -f"; }
      { event = "before-sleep"; command = "${loginctl} lock-session"; }
    ];

    timeouts = [
      {
        timeout = 210;
        command = "${brightnessctl} --save -e set 20%-";
        resumeCommand = "${brightnessctl} --restore";
      }
      {
        timeout = 240;
        command = "${loginctl} lock-session";
      }
      {
        timeout = 270;
        command = "${niri} msg action power-off-monitors";
      }
    ];
  };

  services.syncthing.enable = true;

  systemd.user.services = {
    swayidle = {
      Unit = {
        After = [ "graphical-session.target" ];
      };
    };
  };

  xdg.mimeApps.enable = true;

  xdg.portal = {
    enable = true;
    configPackages = [ config.programs.niri.package ];
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      (xdg-desktop-portal-gtk.override { buildPortalsInGnome = false; })
    ];
  };
}
