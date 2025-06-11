{ self, ... }@inputs: { lib, config, pkgs, ... }:
let
  inherit (pkgs.stdenv) hostPlatform;
in {
  imports = with self.nixosModules; [
    powersupply
  ];

  nix = {
    channel.enable = false;

    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "best-effort";
    daemonIOSchedPriority = 7;

    gc.automatic = false;

    settings = {
      experimental-features = [
        "auto-allocate-uids"
        "cgroups"
        "flakes"
        "nix-command"
        "pipe-operator"
      ];

      allowed-users = [ "@users" ];
      trusted-users = [ "@wheel" ];

      auto-allocate-uids = true;
      builders-use-substitutes = true;
      download-attempts = 8;
      http-connections = 128;
      max-substitution-jobs = 128;
      preallocate-contents = true;
      use-cgroups = true;
      use-xdg-base-directories = true;

      substituters = [
        "https://cache.kyouma.net"
        "https://colmena.cachix.org"
        "https://catppuccin.cachix.org"
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "cache.kyouma.net:Frjwu4q1rnwE/MnSTmX9yx86GNA/z3p/oElGvucLiZg="
        "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
        "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      # If free storage space drops below 1 GiB, collect garbage until 4 GiB are free
      min-free = 1073741824;
      max-free = 4294967296;
    };

    registry = inputs
      |> lib.filterAttrs (name: value: (lib.types.isType "flake" value) && name != "self")
      |> lib.mapAttrs (name: flake: { inherit flake; });
  };

  system.rebuild.enableNg = lib.mkDefault true;

  systemd = {
    services = {
      nix-daemon.serviceConfig = {
        CPUAccounting = true;
        CPUWeight = 20;

        MemoryAccounting = true;
        MemoryHigh = "80%";

        IOAccounting = true;
        IOWeight = 20;
      };

      nix-gc-gen = {
        description = "Delete old Nix profile generations";
        startAt = "daily";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe' config.nix.package "nix-env"} --delete-generations 7d";
        };
      };
    };

    timers.nix-gc-gen = {
      description = "Regularly delete old Nix profile generations";
      bindsTo = [ "power-external.target" ];
      timerConfig = {
        RandomizedDelaySec = "6h";
        AccuracySec = "1d";
        Persistent = true;
      };
    };
  };
}
