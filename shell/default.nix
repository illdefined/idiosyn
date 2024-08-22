{ colmena, ... }: { mkShell, system }:

let
  inherit (colmena.packages.${system}) colmena;
in mkShell {
  packages = [ colmena ];
  meta = { inherit (colmena.meta) platforms; };
}
