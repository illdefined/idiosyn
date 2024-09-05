{ self, ... }: { lib, config, pkgs, ... }: {
  imports = with self.nixosModules; [ magi ];
}
