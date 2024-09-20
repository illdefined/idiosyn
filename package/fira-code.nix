{ ... }: { stdenv, lib, fetchzip }:

stdenv.mkDerivation (finalAttrs: {
  pname = "fira-code";
  version = "unstable-2024-08-27";

  src = fetchzip {
    url = "https://github.com/illdefined/FiraCode/releases/download/unstable-2024-08-27/Fira_Code_8557c11.zip";
    stripRoot = false;
    hash = "sha256-pcxwlqTntP+/tNOX+MPG+YTiSv1odX4fa3zBfJViQGQ=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -D -m 0644 -t "$out/share/fonts" \
      "variable_ttf/Fira Code/FiraCode-VF.ttf"

    runHook postInstall
  '';
})
