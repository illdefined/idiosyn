{ nixpkgs, ... }: final: prev:
let
  inherit (nixpkgs) lib;
  inherit (prev.stdenv) hostPlatform;
in lib.optionalAttrs hostPlatform.isAarch ({
  umockdev = prev.umockdev.overrideAttrs {
    doCheck = false;
  };

  qemu = if hostPlatform.isStatic
    then prev.qemu.overrideAttrs (prevAttrs: {
        configureFlags = prevAttrs.configureFlags or [ ] ++ [
          "--disable-pie"
        ];
      })
    else prev.qemu;
})
