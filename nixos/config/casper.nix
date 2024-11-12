{ self, ... }: { lib, config, pkgs, ... }: {
  imports = with self.nixosModules; [ magi ];

  ephemeral = {
    enable = true;
    device = "UUID=545bcd08-9f1a-4f42-b85e-93c47d496ac3";
    boot = {
      device = "UUID=A5AE-22E8";
      fsType = "vfat";
    };
  };

  services.ntpd-rs.settings.source = map (address: {
    mode = "server";
    inherit address;
  }) [ "melchior.nyantec.com" "balthasar.nyantec.com" ]
  |> lib.mkAfter;
}
