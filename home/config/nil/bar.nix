{ ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };

  brightnessctl = lib.getExe pkgs.brightnessctl;
  busctl = osConfig.systemd.package + /bin/busctl;
  gammarelay = lib.getExe pkgs.wl-gammarelay-rs;
  pwvucontrol = lib.getExe pkgs.pwvucontrol;
  rfkill = pkgs.util-linux + /bin/rfkill;
  wpctl = osConfig.services.pipewire.wireplumber.package + /bin/wpctl;
  wttrbar = pkgs.wttrbar + /bin/wttrbar;

  gr = cmd: "${busctl} --user -- ${cmd} rs.wl-gammarelay / rs.wl.gammarelay";
  gr-set = gr "set-property";
  gr-call = gr "call";
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    package = pkgs.waybar.override {
      cavaSupport = false;
      hyprlandSupport = false;
      jackSupport = false;
      mpdSupport = false;
      sndioSupport = false;
    };

    style = pkgs.writeText "waybar-style.css"
      (with config.lib.stylix.colors.withHashtag; ''
        * {
          font: 600 12pt sans-serif;
        }

        window > box {
          padding: 1.5mm 3mm;
        }

        window, tooltip {
          background: ${base00};
          color: ${base05};
        }

        tooltip {
          border-color: ${base0D};
        }

        label.module {
          padding: 0 3mm;
          min-width: 5mm;
        }

        #battery.warning {
          color: ${yellow};
        }

        #battery.critical {
          color: ${red};
        }

        #temperature.critical {
          color: ${red};
        }

        #idle_inhibitor.activated {
          color: ${yellow};
        }

        #pulseaudio.sink.muted {
          color: ${base03};
        }

        #pulseaudio.source {
          color: ${yellow};
        }

        #pulseaudio.source.source-muted {
          color: ${base03};
        }
      '') |> lib.mkForce;

    settings = {
      main = {
        layer = "top";
        position = "bottom";
        spacing = 0;

        modules-left = [ "tray" ];
        modules-center = [ "mpris" ];
        modules-right = [
          "idle_inhibitor"
          "network"
          "bluetooth"
          "temperature"
          "cpu"
          "memory"
          "disk"
          "backlight"
          "custom/gammarelay"
          "pulseaudio#sink"
          "pulseaudio#source"
          "battery"
          "custom/weather"
          "clock"
        ];

        mpris = {
          interval = 1;
          format = "{status_icon} {dynamic} {player_icon}";
          dynamic-order = [ "title" "artist" "position" "length" ];
          dynamic-separator = " – ";
          ellipsis = "…";

          player-icons = {
            default = "";
            mopidy = "";
            mpv = "";
          };

          status-icons = {
            playing = "";
            paused = "";
            stopped = "";
          };
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󱎴";
            deactivated = "󰷛";
          };

          timeout = 15.0;
        };

        network = {
          interval = 10;
          format = "{icon} 󰅀 {bandwidthDownBytes} 󰅃 {bandwidthUpBytes}";
          format-icons = {
            disconnected = "󰌙";
            linked = "󰌚";
            ethernet = "󰌘";
            wifi = [ "󰤯" "󰤟" "󰤢" "󰤢" "󰤨" ];
          };

          tooltip-format = "{ifname}";
          tooltip-format-wifi = "{essid} ({signalStrength} %)";
        };

        bluetooth = {
          format = "";
          format-off = "󰂲";
          format-on = "󰂯";
          format-connected = "󰂱";
          format-connected-battery = "󰥈 {device_battery_percentage} %";

          on-click-right = "${rfkill} toggle bluetooth";

          tooltip-format-connected-battery = "{device_enumerate}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_battery_percentage} %";
        };

        cpu = {
          format = " {usage} %";
        };

        memory = {
          format = " {percentage} %  {swapPercentage} %";
          tooltip-format = "{used:0.1f} / {total:0.1f} GiB\n{swapUsed:0.1f} / {swapTotal:0.1f} GiB";
          states = {
            warning = 96;
            critical = 99;
          };
        };

        temperature = let
          fmt = "{temperatureC} °C";
        in {
          format = "󰔏 ${fmt}";
          format-critical = "󰸁 ${fmt}";
          tooltip-format = fmt;
        };

        disk = {
          format = " {percentage_used} %";
          path = "/home";
          tooltip-format = "{used} / {total}";
        };

        "backlight" = let
          fmt = "{percent} %";
        in {
          format = "{icon} ${fmt}";
          format-icons = [ "󰛩" "󱩎" "󱩐" "󱩐" "󱩑" "󱩒" "󱩓" "󱩔" "󱩕" "󱩖" "󰛨" ];

          on-click = "${brightnessctl} set 100%";
          on-click-right = "${brightnessctl} set 5%";
          on-scroll-up = "${brightnessctl} set +1%";
          on-scroll-down = "${brightnessctl} set 1%-";

          tooltip-format = fmt;
        };

        "custom/gammarelay" = let
          fmt = "{} K";
        in {
          format = "󰖦 ${fmt}";
          exec = "${gammarelay} watch {t}";

          on-click = "${gr-set} Temperature q 6500";
          on-click-right = "${gr-set} Temperature q 4500";
          on-scroll-up = "${gr-call} UpdateTemperature n +100";
          on-scroll-down = "${gr-call} UpdateTemperature n -100";

          tooltip-format = fmt;
        };

        battery = {
          states = {
            warning = 25;
            critical = 15;
          };

          format = "{icon} {capacity} %";
          format-icons = {
            full = "󱟢";
            plugged = "󰚥";
            charging = [ "󰢟" "󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅" ];
            discharging = [ "󱃍" "󰁺" "󰁻" "󰁼" "󰁽" "󰁿" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          };

          format-time = "{H}:{M}";
          weighted-average = true;
        };

        "pulseaudio#sink" = let
          fmt = "{volume} %";
        in {
          format = "{icon} ${fmt}";
          format-bluetooth = "󰂰 ${fmt}";
          format-muted = "󰖁 ${fmt}";

          format-icons = {
            headphone = "";
            default = [ "󰕿" "󰖀" "󰕾" ];
          };

          on-click = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-click-right = pwvucontrol;
          on-scroll-up = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 1%+";
          on-scroll-down = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 1%-";

          max-volume = 100;
        };

        "pulseaudio#source" = let
          fmt = "{volume} %";
        in {
          format = "{format_source}";
          format-source = "󰍬 ${fmt}";
          format-source-muted = "󰍭 ${fmt}";

          on-click = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          on-click-right = pwvucontrol;
          on-scroll-up = "${wpctl} set-volume @DEFAULT_AUDIO_SOURCE@ 1%+";
          on-scroll-down = "${wpctl} set-volume @DEFAULT_AUDIO_SOURCE@ 1%-";
        };

        "custom/weather" = {
          exec = "${wttrbar} --hide-conditions --custom-indicator '{ICON} {temp_C} °C'";
          return-type = "json";
          interval = 900;
        };

        clock = {
          interval = 1;
          format = " {:%H:%M:%S %Z}";
          format-alt = "󰃭 {:%Y-%m-%d}";

          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            weeks-pos = "left";
            on-scroll = 1;
            format = {
              weeks = "{:%W}";
            };
          };

          actions = {
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };
      };
    };
  };

  systemd.user.targets = {
    tray = {
      Unit = {
        BindsTo = [ "waybar.service" ];
        After = [ "waybar.service" ];
      };
    };
  };
}
