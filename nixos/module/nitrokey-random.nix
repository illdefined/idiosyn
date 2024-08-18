{ ... }: { config, lib, pkgs, ... }:

lib.mkIf config.hardware.nitrokey.enable {
  services.udev.packages = [
    (pkgs.writeTextDir "etc/udev/rules.d/98-nitrokey-random-seed.rules" ''
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="20a0", ATTRS{idProduct}=="42b1|42b2", TAG+="systemd", ENV{SYSTEMD_WANTS}+="nitrokey-random-seed@%k.service"
    '')
  ];

  systemd.services."nitrokey-random-seed@" = {
    description = "Feed kernel from Nitrokey TRNG";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.pynitrokey}/bin/nitropy fido2 rng feedkernel";
      DynamicUser = true;
      SupplementaryGroups = [ "plugdev" ];
      AmbientCapabilities = [ "CAP_SYS_ADMIN" ];

      DeviceAllow = [ "/dev/%i rw" ];
      DevicePolicy = "closed";
    };
  };
}
