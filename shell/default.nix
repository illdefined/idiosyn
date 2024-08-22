{ colmena, ... }: { mkShell, system }:

mkShell {
  packages = [ colmena.packages.${system}.colmena ];
  meta.platforms = colmena.packages.${system}.colmena.meta.platforms;
}
