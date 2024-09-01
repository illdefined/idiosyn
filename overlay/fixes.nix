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
      psutil = prev.psutil.overrideAttrs ({
        doCheck = false;
      });
    };
  };
} // optionalAttrs hostPlatform.isRiscV64 ({
  libuv = prev.libuv.overrideAttrs ({
    doCheck = false;
  });
})
