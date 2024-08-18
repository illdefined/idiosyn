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

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
}
