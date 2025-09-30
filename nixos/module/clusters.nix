{ ... }: { config, lib, ... }:

let
  cfg = config.hardware.cpu.clusters;

  concat = set: set
    |> lib.sort (p: q: p < q)
    |> lib.unique
    |> lib.concatMapStringsSep "," toString;

  performance = concat cfg.performance;
  efficiency = concat cfg.efficiency;
  combined = concat (cfg.performance ++ cfg.efficiency);
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
      sliceConfig.StartupAllowedCPUs = combined;
    });

    systemd.user.slices = lib.genAttrs [ "session" "background" ] (slice: {
      sliceConfig.AllowedCPUs = efficiency;
      sliceConfig.StartupAllowedCPUs = combined;
    });

    assertions = lib.singleton {
      assertion = lib.mutuallyExclusive cfg.performance cfg.efficiency;
      message = "Performance and efficiency clusters must not overlap";
    };
  };
}
