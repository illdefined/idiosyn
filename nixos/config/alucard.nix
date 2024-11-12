{ self, nixos-hardware, ... }: { lib, config, pkgs, ... }: {
  imports = with self.nixosModules; [
    default
    headless
    mimalloc
    physical
  ];

  networking = {
    domain = "nyantec.com";
  };

  services.gobgpd = {
    enable = true;
    settings = {
      global = {
        as = 208250;
        router-id = "45.150.121.0";
      };

      neighbors = [
      ] ++ map (n: {
        config = {
          neighbor-address = "2a0f:be00:1::${toString n}";
          peer-as = 208250;
        };
      }) [ 1 2 3 ];
    };
  };

  services.ntpd-rs = {
    enable = true;
    settings = {
      source = map (address: {
        mode = "server";
        inherit address;
      }) (map (n: "ptbtime${toString n}.ptb.de") (lib.range 1 4)
      ++ map (host: "${host}.nyantec.com") [ "casper" "melchior" "balthasar" ]);
    };
  };
}
