{ ... }: pkgs: stdenv:

let
  inherit (lib) optionalAttrs optionals toList;
  inherit (pkgs) lib;
  inherit (stdenv) targetPlatform;
in pkgs.addAttrsToDerivation (prevAttrs: let
  overrideAlloc = prevAttrs.overrideAlloc or true;

  inputs = optionals overrideAlloc [ pkgs.mimalloc ];

  cflagsE = [ "-flto" ];
  cflagsC = [ "-pipe" ];
  cflagsL = [ /*"-fuse-ld=lld"*/ ];

  ldflags = [
    "-O2"
    "--hash-style=gnu"
    /*"--icf=safe"
    "--lto-O2"*/
  ] ++ optionals overrideAlloc [ "-lmimalloc" ];

  rustflags = [
    "-C" "opt-level=2"
    "-C" "linker-flavor=ld.lld"
    "-C" "lto"
    "-C" "linker-plugin-lto"
  ] ++ optionals (targetPlatform.isx86_64 && targetPlatform ? gcc.arch) [
    "-C" "target-cpu=${targetPlatform.gcc.arch}"
  ] ++ (map (flag: [ "-C" "link-arg=${flag}" ]) ldflags |> lib.flatten);

  goflags = [ "-ldflags=-linkmode=external" ];
in {
  buildInputs = prevAttrs.buildInputs or [ ] ++ inputs;

  env = prevAttrs.env or { } // optionalAttrs (!prevAttrs ? CFLAGS) {
    CFLAGS = toList prevAttrs.CFLAGS or [ ] ++ cflagsE |> toString;
  } // optionalAttrs (!prevAttrs ? NIX_CFLAGS_COMPILE) {
    NIX_CFLAGS_COMPILE = toList prevAttrs.env.NIX_CFLAGS_COMPILE or [ ] ++ cflagsC |> toString;
  } // optionalAttrs (!prevAttrs ? NIX_CFLAGS_LINK) {
    NIX_CFLAGS_LINK = toList prevAttrs.env.NIX_CFLAGS_LINK or [ ] ++ cflagsL |> toString;
  } // optionalAttrs (prevAttrs ? env.NIX_LDFLAGS) {
    NIX_LDFLAGS = toList prevAttrs.NIX_LDFLAGS or [ ] ++ ldflags |> toString;
  };

  NIX_RUSTFLAGS = prevAttrs.NIX_RUSTFLAGS or [ ] ++ rustflags;
  GOFLAGS = prevAttrs.GOFLAGS or [ ] ++ goflags;
} // optionalAttrs (prevAttrs ? CFLAGS) {
  CFLAGS = toList prevAttrs.CFLAGS or [ ] ++ cflagsE;
} // optionalAttrs (prevAttrs ? NIX_CFLAGS_COMPILE) {
  NIX_CFLAGS_COMPILE = toList prevAttrs.NIX_CFLAGS_COMPILE or [ ] ++ cflagsC;
} // optionalAttrs (prevAttrs ? NIX_CFLAGS_LINK) {
  NIX_CFLAGS_LINK = toList prevAttrs.NIX_CFLAGS_LINK or [ ] ++ cflagsL;
} // optionalAttrs (!prevAttrs ? env.NIX_LDFLAGS) {
  NIX_LDFLAGS = toList prevAttrs.NIX_LDFLAGS or [ ] ++ ldflags;
}) stdenv
