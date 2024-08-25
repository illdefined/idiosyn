{ ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird;
    profiles = { };
  };
}
