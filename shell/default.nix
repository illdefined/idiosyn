{ colmena, ... }: { mkShell, system }:

mkShell {
  packages = [ colmena.packages.${system}.colmena ];
}
