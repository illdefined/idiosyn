{ ... }: { lib, config, pkgs, ... }: {
  # Work around TTL‐based rate limiting in mobile networks
  boot.kernel.sysctl."net.ipv4.ip_default_ttl" = 65;

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  powerManagement.scsiLinkPolicy = lib.mkDefault "med_power_with_dipm";

  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };

      charger = {
        governor = "powersave";
        turbo = "auto";
      };
    };
  };

  services.thermald.enable = lib.mkDefault true;
  services.tlp.enable = false;

  services.udev.packages = [
    (pkgs.writeTextDir "/etc/udev/rules.d/98-power-supply-portable.rules" ''
      SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", SYSCTL{vm/dirty_writeback_centisecs}="6000"
      SUBSYSTEM=="power_supply", ATTR{status}!="Discharging", SYSCTL{vm/dirty_writeback_centisecs}="1500"
      SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[3-5]", RUN+="${config.systemd.package}/bin/systemctl suspend"
      SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-2]", RUN+="${config.systemd.package}/bin/systemctl poweroff"
    '')
  ];
}
