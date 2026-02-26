{ ... }: { config, lib, pkgs, name, ... }: {
  networking.hostName = lib.mkDefault name;
  networking.nftables.enable = true;
  networking.resolvconf.enable = false;
  networking.useNetworkd = true;

  environment.etc."resolv.conf".text = ''
    nameserver ::1
    nameserver 127.0.0.1
    options timeout:30 edns0 trust-ad
  '';

  services.resolved.enable = false;

  services.unbound = {
    enable = true;
    package = pkgs.unbound-with-systemd.override {
      withTFO = true;
    };

    settings = {
      server = {
        num-threads = lib.max 2 (builtins.length config.hardware.cpu.clusters.efficiency);

        interface = [ "lo" ];
        access-control = [
          "::1/128 allow"
          "127.0.0.0/8 allow"
        ];

        # upstream
        tls-upstream = true;
        tls-cert-bundle = config.security.pki.caBundle;

        # downstream buffer sizes
        edns-buffer-size = 65552;
        max-udp-size = 65536;
        stream-wait-size = "64m";

        # cache
        msg-cache-size = "16m";
        rrset-cache-size = "32m";
        cache-min-ttl = 60;
        cache-max-negative-ttl = 300;

        # serve expired cache entries
        prefetch = true;
        prefetch-key = true;
        serve-expired = true;
        ede = true;
        ede-serve-expired = true;
        val-log-level = 2;  # allow descriptive EDNS errors
      };

      forward-zone = [
        {
          name = ".";
          forward-tls-upstream = true;
          forward-addr = [
            "2a01:4f8:1c0c:6c89::1#resolve.nyantec.com"
            "2a01:4f9:c011:b2f4::1#resolve.nyantec.com"
            "116.203.220.161#resolve.nyantec.com"
            "95.216.222.55#resolve.nyantec.com"
          ];
        }
      ];
    };
  };

  systemd.network.networks =
  let
    networkConfig = metric: matchConfig: {
      inherit matchConfig;

      DHCP = lib.mkDefault "yes";

      dhcpV4Config.UseDNS = false;
      dhcpV6Config.UseDNS = false;
      ipv6AcceptRAConfig.Token = "prefixstable";
    } // lib.optionalAttrs (metric != null) {
      dhcpV4Config.RouteMetric = metric;
      ipv6AcceptRAConfig.RouteMetric = metric;
    };
  in {
    "99-ethernet-default-dhcp" = networkConfig null {
      Type = "ether";
      Kind = "!*";
    };

    "99-wireless-client-dhcp" = networkConfig 1025 {
      Type = "wlan";
      WLANInterfaceType = "station";
    };
  };
}
