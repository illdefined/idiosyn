{ ... }: {
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  hexyl,
  nix-update-script
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hexyl.yazi";
  version = "0-unstable-2025-02-22";

  src = fetchFromGitHub {
    owner = "Reledia";
    repo = "hexyl.yazi";
    rev = "228a9ef2c509f43d8da1847463535adc5fd88794";
    hash = "sha256-Xv1rfrwMNNDTgAuFLzpVrxytA2yX/CCexFt5QngaYDg=";
  };

  buildInputs = [ hexyl ];

  buildCommand = ''
    mkdir -p "$out"
    cp ${finalAttrs.src}/*.lua "$out"
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
