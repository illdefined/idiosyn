{ self, lanzaboote, ... }: { config, lib, pkgs, ... }: {
  imports = [
    lanzaboote.nixosModules.lanzaboote
  ] ++ (with self.nixosModules; [
    nitrokey-random
  ]);

  boot = {
    loader.efi.canTouchEfiVariables = true;

    lanzaboote = {
      enable = true;
      pkiBundle = lib.mkDefault "/var/lib/sbctl";
    };
  };

  security.tpm2.enable = lib.mkDefault true;
  services.fwupd.enable = lib.mkDefault true;
}
