{ ... }: { lib, name, ... }: {
  networking.nameservers = [
    "[2a05:f480:1800:d2e::1]:853#resolve.solitary.social"
    "80.240.30.163:853#resolve.solitary.social"
    "[2a01:4f8:1c0c:6c89::1]:853#resolve.nyantec.com"
    "116.203.220.161:853#resolve.nyantec.com"
  ];

  networking.hostName = lib.mkDefault name;
  networking.nftables.enable = true;
  networking.useNetworkd = true;

  services.resolved = {
    enable = true;
    dnsovertls = "true";
    dnssec = "true";
    fallbackDns = [
      "2001:67c:930::1#wikimedia-dns.org"
      "2620:fe::11#dns11.quad9.net"
      "185.71.138.138#wikimedia-dns.org"
      "9.9.9.11#dns11.quad9.net"
    ];
  };

  systemd.network.networks."98-ethernet-default-dhcp" = {
    matchConfig.Type = "ether";
    matchConfig.Name = "en*";

    DHCP = lib.mkDefault "yes";
    dhcpV4Config.UseDNS = false;
    dhcpV6Config.UseDNS = false;
    ipv6AcceptRAConfig.Token = "prefixstable";

    fairQueueingConfig.Pacing = true;
  };

  systemd.network.networks."98-wireless-client-dhcp" = {
    matchConfig.Type = "wlan";
    matchConfig.WLANInterfaceType = "station";

    DHCP = lib.mkDefault "yes";
    dhcpV4Config.UseDNS = false;
    dhcpV4Config.RouteMetric = 1025;
    dhcpV6Config.UseDNS = false;
    ipv6AcceptRAConfig.Token = "prefixstable";
    ipv6AcceptRAConfig.RouteMetric = 1025;

    cakeConfig = {
      Bandwidth = lib.mkDefault "100M";
      AutoRateIngress = true;
      UseRawPacketSize = false;
      PriorityQueueingPreset = "diffserv4";
    };
  };
}
