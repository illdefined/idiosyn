{ nixpkgs, ... }: final: prev: 
let
  inherit (nixpkgs) lib;
  inherit (prev.stdenv) hostPlatform;
in lib.optionalAttrs hostPlatform.isRiscV ({
  python312 = prev.python312.override {
    packageOverrides  = final: prev: {
      psutil = prev.psutil.overrideAttrs (prevAttrs: {
        disabledTests = prevAttrs.disabledTests or [ ] ++ [
          "net_if_addrs"
          "net_if_stats"
        ];
      });
    };
  };

  boehmgc = prev.boehmgc.overrideAttrs (prevAttrs: {
    postPatch = prevAttrs.postPatch or "" + ''
      sed -E -i '/^TESTS \+= gctest/d' \
        tests/tests.am
    '';
  });

  elfutils = prev.elfutils.overrideAttrs {
    doCheck = false;
    doInstallCheck = false;
  };

  libseccomp = prev.libseccomp.overrideAttrs {
    doCheck = false;
  };

  libuv = prev.libuv.overrideAttrs {
    doCheck = false;
  };

  umockdev = prev.umockdev.overrideAttrs {
    doCheck = false;
  };

  xdg-utils = prev.xdg-utils.override {
    procmail = final.emptyDirectory;
  };
})
