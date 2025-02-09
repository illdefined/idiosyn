{ self, ... }: { lib, config, pkgs, ... }: {
  imports = with self.nixosModules; [ magi ];

  ephemeral = {
    enable = true;
    device = "UUID=";
    boot = {
      device = "UUID=";
      fsType = "vfat";
    };
  };

  services.ntpd-rs.settings.source = map (address: {
    mode = "server";
    inherit address;
  }) [ "casper.nyantec.com" "balthasar.nyantec.com" ]
  |> lib.mkAfter;
}
