{ self, ... }: { config, lib, pkgs, ... }: let
  monthly = {
    OnCalendar = "monthly";
    RandomizedDelaySec = "1w";
  };

  timers = {
    "btrfs-scrub@nix" = monthly;
    "btrfs-scrub@home" = monthly;
    "btrfs-scrub@var" = monthly;
    "btrfs-balance@nix" = monthly;
  };
in {
  imports = with self.nixosModules; [
    powersupply
  ];

  systemd = {
    services =
    let
      btrfs = "${pkgs.btrfs-progs}/bin/btrfs";

      service = serviceConfig: {
        unitConfig = {
          ConditionPathIsMountPoint = "%f";
          RequiresMountsFor = "%f";
          Requisite = [ "power-external.target" ];
          StopPropagatedFrom = [ "power-external.target" ];
        };

        serviceConfig = {
          Type = "exec";
          KillSignal = "SIGINT";

          CPUSchedulingPolicy = "batch";
          IOSchedulingClass = "idle";
          CPUWeight = "idle";
        } // serviceConfig;
      };
    in {
      "btrfs-scrub@" = service {
        ExecStart = "${btrfs} scrub start -B %f";
        BindPaths = [ "%f:%f:norbind" ];
      };

      "btrfs-balance@" = service {
        ExecStart = "${btrfs} balance start -dusage=10 -musage=5 %f";
      };
    } // lib.mapAttrs (name: _: {
      overrideStrategy = "asDropin";
    }) timers;

    timers = lib.mapAttrs (name: timerConfig: {
      bindsTo = [ "power-external.target" ];

      unitConfig = {
        ConditionPathIsMountPoint = "%f";
        RequiresMountsFor = "%f";
      };

      timerConfig = timerConfig // {
        Persistent = true;
      };
    }) timers;
  };
}
