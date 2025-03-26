{ ... }: {
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  git,
  nix-update-script
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "git.yazi";
  version = "0-unstable-2025-03-19";

  src = fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "273019910c1111a388dd20e057606016f4bd0d17";
    hash = "sha256-80mR86UWgD11XuzpVNn56fmGRkvj0af2cFaZkU8M31I=";
  };

  buildInputs = [ git ];

  buildCommand = ''
    mkdir -p "$out"
    cp ${finalAttrs.src}/git.yazi/*.lua "$out"
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
