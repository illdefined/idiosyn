{ firefox, ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  programs.thunderbird = {
    enable = true;
    package = firefox.packages.${pkgs.system}.thunderbird;
    profiles = { };
  };
}
