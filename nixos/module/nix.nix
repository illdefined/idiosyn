{ self, ... }@inputs: { lib, pkgs, ... }:
let
  inherit (pkgs.stdenv) hostPlatform;
in {
  imports = with self.nixosModules; [
    powersupply
  ];

  nix = {
    package = pkgs.lix.override { enableGC = true; };

    channel.enable = false;

    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "best-effort";
    daemonIOSchedPriority = 7;

    gc = {
      automatic = true;
      dates = "weekly";
      randomizedDelaySec = "24h";
      options = "--delete-older-than 10d";
    };

    settings = {
      experimental-features = [
        "cgroups"
        "flakes"
        "nix-command"
        "repl-flake"
        "pipe-operator"
      ];

      allowed-users = [ "@users" ];
      trusted-users = [ "@wheel" ];

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
    };

    registry = inputs
      |> lib.filterAttrs (name: value: (lib.types.isType "flake" value) && name != "self")
      |> lib.mapAttrs (name: flake: { inherit flake; });
  };

  systemd = {
    services.nix-daemon.serviceConfig.Slice = "nix-build.slice";
    slices.nix-build = { };
    timers.nix-gc.bindsTo = [ "power-external.target" ];
  };
}
