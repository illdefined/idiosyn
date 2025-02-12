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

  security.pam.loginLimits = [
    {
      domain = "@users";
      item = "memlock";
      value = 262144;
    }
  ];

  security.polkit.enable = true;
  security.rtkit.enable = true;

  services.avahi.enable = true;

  services.pipewire = {
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

        "10-airplay" = {
          "context.modules" = [
            {
              name = "libpipewire-module-raop-discover";
            }
          ];
        };
      };
    };
  };
}
