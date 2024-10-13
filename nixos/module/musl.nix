{ ...}: { modulesPath, config, lib, pkgs, ... }: {
  disabledModules = [
    (modulesPath + "/config/ldso.nix")
    (modulesPath + "/config/stub-ld.nix")
    (modulesPath + "/programs/nix-ld.nix")
  ];

  config = lib.mkIf pkgs.hostPlatform.isMusl {
    i18n.glibcLocales = pkgs.stdenvNoCC.mkDerivation {
      pname = "locale-archive-stub";
      version = "0";

      buildCommand = ''
        mkdir -p "$out/lib/locale"
        touch "$out/lib/locale/locale-archive"
      '';
    } |> lib.mkDefault;

    i18n.supportedLocales = lib.mkDefault [ ];
    security.pam.services.login.updateWtmp = lib.mkForce false;
    services.nscd.enable = lib.mkForce false;
    system.nssModules = lib.mkForce [ ];
  };
}
