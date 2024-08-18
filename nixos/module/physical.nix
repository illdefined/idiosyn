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
      pkiBundle = lib.mkDefault "/etc/keys/secureboot";
    };
  };

  security.tpm2.enable = true;
  services.fwupd.enable = true;
}
