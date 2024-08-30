{ ... }: { stdenvNoCC, hostPlatform, lib, shellcheck-minimal, runtimeShell, cage }:

stdenvNoCC.mkDerivation (finalAttrs: {
  name = "wayland-headless";

  nativeInstallCheckInputs = lib.optionals
    finalAttrs.doInstallCheck [ shellcheck-minimal ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  doInstallCheck = !hostPlatform.isRiscV64;

  installPhase = ''
    mkdir -p "$out/bin"

    substitute ${./wl-run.sh} "$out/bin/wl-run" \
      --subst-var-by runtimeShell ${lib.escapeShellArg runtimeShell} \
      --subst-var-by cage ${lib.escapeShellArg cage}

    substitute ${./xvfb-run.sh} "$out/bin/xvfb-run" \
      --subst-var-by runtimeShell ${lib.escapeShellArg runtimeShell} \
      --subst-var out

    chmod +x "$out/bin/"{wl-run,xvfb-run}
  '';

  installCheckPhase = ''
    runHook preInstallCheck
    shellcheck "$out/bin/"{wl-run,xvfb-run}
    runHook postInstallCheck
  '';

  meta = {
    inherit (cage.meta) platforms;
  };
})
