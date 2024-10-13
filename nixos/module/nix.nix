{ self, ... }: { lib, pkgs, ... }:
let
  inherit (pkgs.stdenv) hostPlatform;
in {
  imports = with self.nixosModules; [
    powersupply
  ];

  nix = {
    package = pkgs.lix;

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
    };

    registry = {
      nixpkgs.to = {
        type = "path";
        path = pkgs.path;
        narHash = lib.trim (builtins.readFile
          (pkgs.runCommandLocal "get-nixpkgs-hash"
            { nativeBuildInputs = [ pkgs.nix ]; }
            "nix-hash --type sha256 --sri ${pkgs.path} > $out"));
      };
    };
  };

  systemd = {
    services.nix-daemon.serviceConfig.Slice = "nix-build.slice";
    slices.nix-build = { };
    timers.nix-gc.bindsTo = [ "power-external.target" ];
  };
}
