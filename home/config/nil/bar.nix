{ ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };

  busctl = osConfig.systemd.package + /bin/busctl;
  gammarelay = lib.getExe pkgs.wl-gammarelay-rs;
  pwvucontrol = lib.getExe pkgs.pwvucontrol;
  wpctl = osConfig.services.pipewire.wireplumber.package + /bin/wpctl;

  gr = cmd: "${busctl} --user -- ${cmd} rs.wl-gammarelay / rs.wl.gammarelay";
  gr-get = gr "get-property";
  gr-set = gr "set-property";
  gr-call = gr "call";

  gr-inv = let
    pkg = pkgs.writeShellApplication {
      name = "gammarelay-inverted";
      text = ''
        state="$(${gr-get} Inverted)";

        if [[ "$state" == "b false" ]]; then
          echo 󰹊
        elif [[ "$state" == "b true" ]]; then
          echo 󰌁
        else
          exit 1
        fi
      '';
    };
  in lib.getExe pkg;
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.override {
      cavaSupport = false;
      hyprlandSupport = false;
      jackSupport = false;
      mpdSupport = false;
      sndioSupport = false;
    };

    settings = {
      main = {
        layer = "top";
        position = "bottom";

        modules-left = [
          "tray"
        ];

        modules-center = [ ];

        modules-right = [
          "network#down"
          "network#up"
          "bluetooth"
          "cpu"
          "memory"
          "memory#swap"
          "temperature"
          "disk"
          "battery"
          "idle_inhibitor"
          "custom/gammarelay-temperature"
          "custom/gammarelay-brightness"
          "custom/gammarelay-gamma"
          "custom/gammarelay-invert"
          "mpris"
          "pulseaudio#sink"
          "pulseaudio#source"
          "clock"
        ];

        "network#down" = {
          format = "󰅃 {bandwidthDownBytes}";
        };

        "network#up" = {
          format = "󰅀 {bandwidthUpBytes}";
        };

        bluetooth = {
          format-connected-battery = "󰂯 {device_battery_percentage} %";
          tooltip-format-connected-battery = "{device_enumerate}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_battery_percentage} %";
        };

        cpu = {
          format = " {usage} %";
        };

        memory = {
          format = " {percentage} %";
          tooltip-format = "{used:0.1f} / {total:0.1f} GiB";
        };

        "memory#swap" = {
          format = " {swapPercentage} %";
          tooltip-format = "{swapUsed:0.1f} / {swapTotal:0.1f} GiB";
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

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󱎴";
            deactivated = "󰷛";
          };

          timeout = 15.0;
        };

        "custom/gammarelay-temperature" = {
          format = " {} K";
          exec = "${gammarelay} watch {t}";
          on-click-right = "${gr-set} Temperature q 6500";
          on-scroll-up = "${gr-call} UpdateTemperature n +100";
          on-scroll-down = "${gr-call} UpdateTemperature n -100";
        };

        "custom/gammarelay-brightness" = {
          format = " {} %";
          exec = "${gammarelay} watch {bp}";
          on-click-right = "${gr-set} Brightness d 1";
          on-scroll-up = "${gr-call} UpdateBrightness d +0.01";
          on-scroll-down = "${gr-call} UpdateBrightness d -0.01";
        };

        "custom/gammarelay-gamma" = {
          format = "γ {}";
          exec = "${gammarelay} watch {g}";
          on-click-right = "${gr-set} Gamma d 1";
          on-scroll-up = "${gr-call} UpdateGamma d +0.01";
          on-scroll-down = "${gr-call} UpdateGamma d -0.01";
        };

        "custom/gammarelay-invert" = {
          exec = gr-inv;
          exec-on-event = true;
          interval = 60;

          on-click = "${gr-call} ToggleInverted";
          on-click-right = "${gr-set} Inverted b false";
        };

        battery = let
          fmt = "{capacity} %";
          dis = {
            "5" = "󱃍";
            "10" = "󰁺";
            "20" = "󰁻";
            "30" = "󰁼";
            "40" = "󰁽";
            "50" = "󰁿";
            "60" = "󰁿";
            "70" = "󰂀";
            "80" = "󰂁";
            "90" = "󰂂";
            "100" = "󰁹";
          };

          chr = {
            "5" = "󰢟";
            "10" = "󰢜";
            "20" = "󰂆";
            "30" = "󰂇";
            "40" = "󰂈";
            "50" = "󰢝";
            "60" = "󰂉";
            "70" = "󰢞";
            "80" = "󰂊";
            "90" = "󰂋";
            "100" = "󰂅";
          };
        in {
          states = {
            "5" = 5;
            "10" = 10;
            "20" = 20;
            "30" = 30;
            "40" = 40;
            "50" = 50;
            "60" = 60;
            "70" = 70;
            "80" = 80;
            "90" = 90;
            "100" = 100;
          };

          format-full = "󰚥 ${fmt}";
          format-time = "{H}:{M}";
          weighted-average = true;
        }
        // lib.mapAttrs' (state: icon: {
          name = "format-discharging-${state}";
          value = "${icon} ${fmt}";
        }) dis
        // lib.mapAttrs' (state: icon: {
          name = "format-charging-${state}";
          value = "${icon} ${fmt}";
        }) chr;

        mpris = {
          format = "{status}";
          status-icons = {
            playing = "";
            paused = "";
            stopped = "";
          };
        };

        "pulseaudio#sink" = let
          fmt = "{volume} %";
        in {
          format = "{icon} ${fmt}";
          format-bluetooth = "󰂰 ${fmt}";
          format-muted = " ${fmt}";

          format-icons = {
            headphone = "";
            default = [ "" "" ];
          };

          on-click = pwvucontrol;
          on-click-right = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-scroll-up = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 1%+";
          on-scroll-down = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 1%-";
        };

        "pulseaudio#source" = let
          fmt = "{volume} %";
        in {
          format = "{format_source}";
          format-source = "󰍬 ${fmt}";
          format-source-muted = "󰍭 ${fmt}";

          on-click = pwvucontrol;
          on-click-right = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          on-scroll-up = "${wpctl} set-volume @DEFAULT_AUDIO_SOURCE@ 1%+";
          on-scroll-down = "${wpctl} set-volume @DEFAULT_AUDIO_SOURCE@ 1%-";
        };

        clock = {
          format = " {:%H:%M %Z}";
          format-alt = "󰃭 {:%Y-%m-%d}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            weeks-pos = "left";
            on-scroll = 1;
            format = {
              weeks = "{:%W}";
            };
          };
        };
      };
    };
  };

  systemd.user.services = {
    waybar = {
      Unit = {
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        BindsTo = [ "tray.target" ];
        Before = [ "tray.target" ];
      };

      Service = {
        Type = "exec";
        ExecStart = lib.getExe config.programs.waybar.package;
      };
    };
  };

  systemd.user.targets = {
    tray = {
      Unit = {
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
    };
  };
}
