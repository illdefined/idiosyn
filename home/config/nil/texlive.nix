{ ... }: { config, lib, ... }@args:
let
  osConfig = args.osConfig or { };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: {
      inherit (tpkgs) 
        texlive-scripts

        xelatex-dev
        fontspec
        polyglossia

        hyphen-english
        hyphen-french
        hyphen-german
        hyphen-portuguese
        hyphen-spanish

        koma-script

        amsmath
        bookmark
        booktabs
        csquotes
        hyperref
        multirow
        paralist
        pbox
        preprint
        realscripts
        textpos
        unicode-math
        units
        xecjk
        xecolor
        xfrac
        xltxtra
        xtab
      ;
    };
  };
}
