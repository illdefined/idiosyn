{ ...}: { modulesPath, ... }: {
  disabledModules = [
    (modulesPath + "/config/ldso.nix")
    (modulesPath + "/programs/nix-ld.nix")
    (modulesPath + "/config/stub-ld.nix")
  ];
}
