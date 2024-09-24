{ ... }: { config, lib, pkgs, ... }: {
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    image = config.lib.stylix.pixel "base00";
  };
}
