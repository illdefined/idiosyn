{ self, ... }: { lib, pkgs, ... }:
let
  inherit (pkgs.stdenv) hostPlatform;
in {
  imports = with self.nixosModules; [
    powersupply
  ];

  system.autoUpgrade = {
    enable = true;
    flake = lib.mkDefault "git+https://woof.rip/mikael/idiosyn.git";

    dates = lib.mkDefault "02:00";
    randomizedDelaySec = lib.mkDefault "30min";

    rebootWindow = lib.mkDefault {
      lower = "02:30";
      upper = "05:30";
    };
  }; 

  systemd.timers.nixos-upgrade.bindsTo = [ "power-external.target" ];
}
