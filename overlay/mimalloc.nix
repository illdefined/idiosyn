{ nixpkgs, ... }: final: prev:

let
  inherit (nixpkgs) lib;
in {
  mimalloc = (prev.mimalloc.overrideAttrs (prevAttrs: {
    postPatch = prevAttrs.postPatch or "" + ''
      sed -E -i \
        -e 's/(\{ )1(, UNINIT, MI_OPTION_LEGACY\(purge_decommits,reset_decommits\) \})/\10\2/' \
        -e 's/(\{ )10(,  UNINIT, MI_OPTION_LEGACY\(purge_delay,reset_delay\) \})/\150\2/' \
        src/options.c
    '';
  })).override {
    secureBuild = true;
  };
}
