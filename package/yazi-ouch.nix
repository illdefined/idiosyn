{ ... }: {
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  ouch,
  nix-update-script
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ouch.yazi";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "ndtoan96";
    repo = "ouch.yazi";
    tag = "v${finalAttrs.version}";
    hash = "sha256-oUEUGgeVbljQICB43v9DeEM3XWMAKt3Ll11IcLCS/PA=";
  };

  buildInputs = [ ouch ];

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
