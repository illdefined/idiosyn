{ self, ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  fonts.fontconfig = {
    enable = true;

    defaultFonts = {
      sansSerif = [
        "Lato"
        "M PLUS 1"
        "Noto Sans"
        "Symbols Nerd Font"
        "Unifont"
        "Unifont Upper"
      ];

      serif = [ "Noto Serif" ];

      monospace = [
        "Fira Code"
        "Julia Mono"
        "M PLUS 1 Code"
        "Noto Sans Mono"
        "Symbols Nerd Font Mono"
      ];

      emoji = [ "Noto Color Emoji" ];
    };
  };

  home.packages = with pkgs; [
    julia-mono
    lato
    self.packages.${pkgs.system}.fira-code
    mplus-outline-fonts.githubRelease
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    noto-fonts
    noto-fonts-color-emoji
    unifont
  ];

  stylix.fonts = {
    sansSerif = {
      package = pkgs.lato;
      name = "sans-serif";
    };

    serif = {
      package = pkgs.noto-fonts;
      name = "serif";
    };

    monospace = {
      package = pkgs.fira-code;
      name = "monospace";
    };

    emoji = {
      package = pkgs.noto-fonts-color-emoji;
      name = "emoji";
    };

    sizes = {
      terminal = 11;
      popups = 13;
    };
  };

  xdg.configFile."fontconfig/conf.d/80-fira-code.conf".source = ./fira-code.xml;
}
