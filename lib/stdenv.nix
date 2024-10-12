{ ... }: pkgs:

let
  inherit (lib) optionalAttrs optionals toList;
  inherit (pkgs) lib stdenv;
  inherit (stdenv) targetPlatform;
in pkgs.addAttrsToDerivation (prevAttrs: let
  overrideAlloc = prevAttrs.overrideAlloc or true;

  inputs = optionals overrideAlloc [ pkgs.mimalloc ];

  cflags = [ "-pipe" ];
  ldflags = [
    "-O2"
    "--hash-style=gnu"
  ] ++ optionals overrideAlloc [ "-lmimalloc" ];

  rustflags = [
    "-C" "opt-level=2"
    "-C" "linker-flavor=ld.lld"
    "-C" "lto"
    "-C" "linker-plugin-lto"
    "-C" "link-arg=--icf=safe"
    "-C" "link-arg=--lto-O2"
  ] ++ optionals (targetPlatform.isx86_64 && targetPlatform ? gcc.arch) [
    "-C" "target-cpu=${targetPlatform.gcc.arch}"
  ] ++ (map (flag: [ "-C" "link-arg=${flag}" ]) ldflags |> lib.flatten);
in {
  buildInputs = prevAttrs.buildInputs or [ ] ++ inputs;

  env = prevAttrs.env or { } // optionalAttrs (!prevAttrs ? NIX_CFLAGS_COMPILE) {
    NIX_CFLAGS_COMPILE = toList prevAttrs.env.NIX_CFLAGS_COMPILE or [ ] ++ cflags |> toString;
  } // optionalAttrs (prevAttrs ? env.NIX_LDFLAGS) {
    NIX_LDFLAGS = toList prevAttrs.NIX_LDFLAGS or [ ] ++ ldflags |> toString;
  };

  NIX_RUSTFLAGS = prevAttrs.NIX_RUSTFLAGS or [ ] ++ rustflags;
} // optionalAttrs (prevAttrs ? NIX_CFLAGS_COMPILE) {
  NIX_CFLAGS_COMPILE = toList prevAttrs.NIX_CFLAGS_COMPILE or [ ] ++ cflags;
} // optionalAttrs (!prevAttrs ? env.NIX_LDFLAGS) {
  NIX_LDFLAGS = toList prevAttrs.NIX_LDFLAGS or [ ] ++ ldflags;
}) stdenv
