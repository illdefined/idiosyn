{ nixpkgs, ... }: final: prev: 
let
  inherit (nixpkgs) lib;
  inherit (prev.stdenv) hostPlatform;
in lib.optionalAttrs hostPlatform.isAarch ({
  umockdev = prev.umockdev.overrideAttrs {
    doCheck = false;
  };
})
