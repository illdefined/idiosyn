{ ... }: {
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  poppler-utils,
  libreoffice-fresh,
  nix-update-script
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "office.yazi";
  version = "0-unstable-2025-03-04";

  src = fetchFromGitHub {
    owner = "macydnah";
    repo = "office.yazi";
    rev = "bcd9e9e78835c96eb2bb8b8841e4753704b99b17";
    hash = "sha256-rZas/oMNI6H5lXOixDQcL/dQC+J9VCFrOOIIjjLDUc4=";
  };

  buildInputs = [ poppler-utils libreoffice-fresh ];

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
