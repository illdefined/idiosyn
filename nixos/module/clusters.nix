{ ... }: { config, lib, ... }:

let
  cfg = config.hardware.cpu.clusters;

  concat = lib.concatMapStringsSep "," toString;
  performance = concat cfg.performance;
  efficiency = concat cfg.efficiency;
in {
  options = {
    hardware.cpu.clusters = {
      performance = lib.mkOption {
        type = with lib.types; listOf ints.unsigned;
        default = [ ];
        description = "List of performance CPUs";
      };

      efficiency = lib.mkOption {
        type = with lib.types; listOf ints.unsigned;
        default = [ ];
        description = "List of efficiency CPUs";
      };
    };
  };

  config = lib.mkIf (cfg.performance != [ ] && cfg.efficiency != [ ]) {
    boot.kernelParams = [
      "irqaffinity=${efficiency}"
      "nohz_full=${performance}"
      "rcu_nocbs=all"
    ];

    nix.settings.cores = builtins.length cfg.performance |> lib.mkDefault;

    systemd.services.nix-daemon = lib.mkIf (cfg.performance != [ ]) {
      serviceConfig.AllowedCPUs = performance;
    };

    systemd.slices = lib.genAttrs [ "system" ] (slice: {
      sliceConfig.AllowedCPUs = efficiency;
    });

    systemd.user.slices = lib.genAttrs [ "session" "app" ] (slice: {
      sliceConfig.AllowedCPUs = efficiency;
    });

    assertions = lib.singleton {
      assertion = lib.mutuallyExclusive cfg.performance cfg.efficiency;
      message = "Performance and efficiency clusters must not overlap";
    };
  };
}
