{ ... }: { config, lib, pkgs, ... }: {
  services.udev.packages = [
    (pkgs.writeTextDir "/etc/udev/rules.d/98-power-supply.rules" ''
      SUBSYSTEM=="power_supply", KERNEL=="AC", TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-internal.target power-external.target"
    '')
  ];

  systemd.targets.power-internal = {
    description = "On internal power supply";
    conflicts = [ "power-external.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      ConditionACPower = false;
      DefaultDependencies = false;
    };
  };

  systemd.targets.power-external = {
    description = "On external power supply";
    conflicts = [ "power-internal.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      ConditionACPower = true;
      DefaultDependencies = false;
    };
  };
}
