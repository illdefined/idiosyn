{ ... }: {
  stdenv,
  lib,
  fetchFromGitHub,

  python3,
  ttfautohint,

  fontFeatures ? [ ]
}:

stdenv.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  pname = "fira-code";
  version = "unstable-2024-02-29";

  src = fetchFromGitHub {
    owner = "tonsky";
    repo = "FiraCode";
    rev = "34cced2a1235e2035fb1f258f228b0ed584b8911";
    hash = "sha256-1cLjAqdm2oG39ML9CuVeoQKb9SR1QX9k7qt2cfl7098=";
  };

  nativeBuildInputs = [
    (python3.withPackages (ps: with ps; [ fontmake ]))
    ttfautohint
  ];

  inherit fontFeatures;

  postPatch = ''
    patchShebangs script
  '';

  buildPhase = ''
    runHook preBuild
    ./script/bake_in_features.sh "''${fontFeatures[@]}"
    ./script/build_ttf.sh
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D -m 0644 -t "$out/share/fonts" distr/ttf/Fira\ Code/*.ttf
    runHook postInstall
  '';
})
