{ self, ... }: { lib, config, pkgs, ... }: {
  imports = with self.nixosModules; [ magi ];

  services.ntpd-rs.settings.source = map (address: {
    mode = "server";
    inherit address;
  }) [ "casper.nyantec.com" "balthasar.nyantec.com" ]
  |> lib.mkAfter;
}
