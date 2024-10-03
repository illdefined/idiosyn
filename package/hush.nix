{ ... }: { busybox }:

(busybox.overrideAttrs (prevAttrs: {
  postInstall = ''
    mv $out/bin/{busybox,sh}
  '';

  meta = prevAttrs.meta // {
    mainProgram = "sh";
  };
})).override {
  enableMinimal = true;
  enableAppletSymlinks = false;
  extraConfig = ''
    CONFIG_PIE y

    CONFIG_SH_IS_ASH n
    CONFIG_SH_IS_HUSH y
  '';
}
