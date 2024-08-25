{ ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };

  brightnessctl = lib.getExe pkgs.brightnessctl;
  fish = lib.getExe osConfig.programs.fish.package;
  fuzzel = lib.getExe config.programs.fuzzel.package;
  kitty = lib.getExe config.programs.kitty.package;
  loginctl = osConfig.systemd.package + /bin/loginctl;
  playerctl = config.services.playerctld.package + /bin/playerctl;
  swaylock = lib.getExe config.programs.swaylock.package;
  wpctl = osConfig.services.pipewire.wireplumber.package + /bin/wpctl;
  xdg-open = pkgs.xdg-utils + /bin/xdg-open;

  niri-each-output = let
    pkg = pkgs.writeShellApplication {
      name = "niri-each-output";
      runtimeInputs = [
        config.programs.niri.package
        pkgs.findutils
        pkgs.jq
      ];

      text = ''
        niri msg --json outputs \
          | jq --raw-output0 '. | keys | .[]' \
          | xargs -0 I {} -- niri msg output {} "$1"
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
    libreoffice
    obsidian
    restic
    signal-desktop
  ];

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        prompt = "❯  ";
      };
    };
  };

  programs.niri.settings = {
    prefer-no-csd = true;

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
      };

      default-column-width.proportion = 1. / 3.;

      gaps = 5;

      preset-column-widths = [
        { proportion = 1. / 3.; }
        { proportion = 1. / 2.; }
        { proportion = 2. / 3.; }
      ];
    };

    binds = with config.lib.niri.actions; {
      "Mod+Return".action = spawn [ kitty ];
      "Mod+Shift+Return".action = spawn [ kitty fish "--private" ];
      "Mod+e".action = spawn [ fuzzel ];

      "Mod+Up".action = focus-window-or-workspace-up;
      "Mod+Down".action = focus-window-or-workspace-down;
      "Mod+Left".action = focus-column-left;
      "Mod+Right".action = focus-column-right;

      "Mod+Ctrl+Up".action = move-window-up-or-to-workspace-up;
      "Mod+Ctrl+Down".action = move-window-down-or-to-workspace-down;
      "Mod+Ctrl+Left".action = move-column-left;
      "Mod+Ctrl+Right".action = move-column-right;

      "Mod+WheelScrollUp".action = focus-window-up-or-column-left;
      "Mod+WheelScrollDown".action = focus-window-down-or-column-right;

      "Mod+g".action = consume-window-into-column;
      "Mod+b".action = expel-window-from-column;

      "Mod+Print".action = screenshot;
      "Mod+Ctrl+Print".action = screenshot-window;
      "Mod+Shift+Print".action = screenshot-screen;

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
      NIXOS_OZONE_WL = "1";
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
        command = "${niri-each-output} off";
        resumeCommand = "${niri-each-output} on";
      }
    ];
  };

  xdg.mimeApps.enable = true;

  xdg.portal = {
    enable = true;
    configPackages = [ config.programs.niri.package ];
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
  };
}
