{ nixpkgs, ... }: final: prev:

let
  inherit (nixpkgs) lib;
in {
  mimalloc = (prev.mimalloc.overrideAttrs (prevAttrs: {
    overrideAlloc = false;
    postPatch = prevAttrs.postPatch or "" + ''
      sed -E -i \
        -e 's/(\{ )1(, UNINIT, MI_OPTION_LEGACY\(purge_decommits,reset_decommits\) \})/\10\2/' \
        -e 's/(\{ )0(, UNINIT, MI_OPTION_LEGACY\(allow_large_os_pages,large_os_pages\) \})/\11\2/' \
        -e 's/(\{ )10(,  UNINIT, MI_OPTION_LEGACY\(purge_delay,reset_delay\) \})/\150\2/' \
        src/options.c
    '';
  })).override {
    secureBuild = true;
  };

  fractal = prev.fractal.overrideAttrs (prevAttrs: {
    nativeBuildInputs = prevAttrs.nativeBuildInputs or [ ] ++ [ final.makeBinaryWrapper ];
    postInstall = prevAttrs.postInstall or "" + ''
      wrapProgram "$out/bin/fractal" \
        --set MIMALLOC_RESERVE_HUGE_OS_PAGES 1
    '';
  });
  
  mpv = final.mpv-unwrapped.wrapper {
    mpv = final.mpv-unwrapped;
    extraMakeWrapperArgs = [ "--set" "MIMALLOC_RESERVE_HUGE_OS_PAGES" "1" ];
  };

  perl = prev.perl.overrideAttrs {
    overrideAlloc = false;
  };
}
