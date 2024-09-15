{ nixpkgs, ... }: final: prev: 
let
  inherit (nixpkgs.lib) optionalAttrs;
  inherit (prev.stdenv) hostPlatform;
in {
  redis = prev.redis.overrideAttrs ({
    doCheck = false;
  });

  python312 = prev.python312.override {
    packageOverrides = final: prev: {
      pywebview = prev.pywebview.overrideAttrs ({
        doCheck = false;
        doInstallCheck = false;
      });
    } // optionalAttrs hostPlatform.isRiscV64 {
      psutil = prev.psutil.overrideAttrs (prevAttrs: {
        disabledTests = prevAttrs.disabledTests or [ ] ++ [
          "net_if_addrs"
          "net_if_stats"
        ];
      });
    };
  };
} // optionalAttrs hostPlatform.isRiscV64 ({
  boehmgc = prev.boehmgc.overrideAttrs (prevAttrs: {
    postPatch = prevAttrs.postPatch or "" + ''
      sed -E -i '/^TESTS \+= gctest/d' \
        tests/tests.am
    '';
  });

  libseccomp = prev.libseccomp.overrideAttrs ({
    doCheck = false;
  });

  libuv = prev.libuv.overrideAttrs ({
    doCheck = false;
  });

  xdg-utils = prev.xdg-utils.override {
    procmail = final.emptyDirectory;
  };
})
