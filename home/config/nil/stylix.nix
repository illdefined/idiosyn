{ ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };
in {
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    image = config.lib.stylix.pixel "base00";

    targets.gtk.enable = osConfig.hardware.graphics.enable or false;
  };
}
