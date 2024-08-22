{ colmena, ... }: { mkShell, system, lib }:

mkShell {
  packages = [ colmena.packages.${system}.colmena ];
  meta.platforms = lib.attrNames colmena.packages;
}
