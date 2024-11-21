{ nixpkgs, ... }: final: prev: 
let
  inherit (nixpkgs) lib;
  inherit (lib) toList;
  inherit (prev.stdenv) hostPlatform;
in {
  redis = prev.redis.overrideAttrs {
    doCheck = false;
  };

  python312 = prev.python312.override {
    packageOverrides = final: prev: {
      pywebview = prev.pywebview.overrideAttrs ({
        doCheck = false;
        doInstallCheck = false;
      });
    };
  };

  sioyek = prev.sioyek.overrideAttrs (prevAttrs: {
    env = prevAttrs.env or { } // {
      NIX_CFLAGS_COMPILE = toList prevAttrs.env.NIX_CFLAGS_COMPILE or [ ]
        ++ [ "-DGL_CLAMP=GL_CLAMP_TO_EDGE" ] |> toString;
    };
  });

  zeromq = prev.zeromq.overrideAttrs (prevAttrs: {
    postPatch = prevAttrs.postPatch or "" + ''
      substituteInPlace CMakeLists.txt \
        --replace-fail 'CACHELINE_SIZE EQUAL "undefined"' 'CACHELINE_SIZE STREQUAL "undefined"'
    '';
  });
}
