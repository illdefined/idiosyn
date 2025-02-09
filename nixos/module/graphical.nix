{ ... }: { config, lib, pkgs, ... }: {
  boot.kernel.sysctl = {
    "kernel.sysrq" = lib.mkDefault "0x1f4";
    "kernel.unprivileged_userns_clone" = lib.mkDefault 1;
  };

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  hardware.graphics.enable = true;

  security.polkit.enable = true;
  security.rtkit.enable = true;

  services.avahi.enable = true;

  services.pipewire = let
    volume-limit = {
      "channelmix.min-volume" = 0.0;
      "channelmix.max-volume" = 1.0;
    };
  in {
    enable = true;
    pulse.enable = true;
    raopOpenFirewall = true;

    extraConfig = {
      pipewire = {
        "10-clock-rate" = {
          "context.properties" = {
            "default.clock.rate" = 96000;
            "default.clock.allowed-rates" = [ 16000 32000 44100 48000 88200 96000 176400 192000 ];
          };
        };

        "10-null-volume" = {
          "context.modules" = [
            {
              name = "libpipewire-module-null-sink";
              args = { inherit volume-limit; };
            }
          ];
        };

        "10-airplay" = {
          "context.modules" = [
            {
              name = "libpipewire-module-raop-discover";
            }
          ];
        };
      };

      client = {
        "10-volume" = {
          "stream.properties" = { inherit volume-limit; };
        };        
      };

      client-rt = {
        "10-volume" = {
          "stream.properties" = { inherit volume-limit; };
        };        
      };

      pipewire-pulse = {
        "10-volume" = {
          "stream.properties" = { inherit volume-limit; };
        };
      };
    };

    wireplumber.extraConfig = {
      "10-volume" = {
        "stream.properties" = { inherit volume-limit; };

        "monitor.alsa.rules" = [
          {
            matches = [
              { "device.api" = "alsa"; }
            ];

            actions = [
              {
                update-props = { inherit volume-limit; };
              }
            ];
          }
        ];
      };
    };
  };
}
