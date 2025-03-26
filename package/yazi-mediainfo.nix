{ ... }: {
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  mediainfo,
  nix-update-script
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mediainfo.yazi";
  version = "0-unstable-2025-03-07";

  src = fetchFromGitHub {
    owner = "boydaihungst";
    repo = "mediainfo.yazi";
    rev = "447fe95239a488459cfdbd12f3293d91ac6ae0d7";
    hash = "sha256-U6rr3TrFTtnibrwJdJ4rN2Xco4Bt4QbwEVUTNXlWRps=";
  };

  buildInputs = [ mediainfo ];

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
