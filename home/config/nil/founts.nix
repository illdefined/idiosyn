{ iosevka, ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };

  inherit (iosevka.packages.${pkgs.system}) iosevka-idiosyn-sans-term;
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
        "idiosyn sans term"
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
    fira-code
    iosevka-idiosyn-sans-term
    julia-mono
    lato
    mplus-outline-fonts.githubRelease
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-color-emoji
    unifont
  ];

  xdg.configFile."fontconfig/conf.d/80-fira-code.conf".source = ./fira-code.xml;
}
