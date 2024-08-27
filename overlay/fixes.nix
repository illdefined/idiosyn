{ nixpkgs, ... }: final: prev: 
let
  inherit (nixpkgs.lib) optionalAttrs;
  inherit (prev.stdenv) hostPlatform;
in {
  redis = prev.redis.overrideAttrs ({
    doCheck = false;
  });
} // optionalAttrs hostPlatform.isRiscV64 ({
  libuv = prev.libuv.overrideAttrs ({
    doCheck = false;
  });
})
