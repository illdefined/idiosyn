{ self, linux-hardened, ... }: { lib, config, pkgs, ... }: {
  imports = with self.nixosModules; [
    default
    headless
    mimalloc
    physical
  ];

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" "riscv64-linux" ];
    preferStaticEmulators = true;
  };

  boot.kernelParams = [
    "hugepagesz=1G" "hugepages=16"
  ];

  boot.kernelPackages = let
    inherit (linux-hardened.packages.x86_64-linux) supermicro-h11ssw;
  in pkgs.linuxPackagesFor (supermicro-h11ssw.override {
    extraProfiles = {
      dm-crypt = true;
    };

    extraConfig = with linux-hardened.lib.kernel; {
      BLK_DEV_MD = true;
      MD_AUTODETECT = true;
      MD_RAID1 = true;
      DM_RAID = true;

      MLX4_EN = true;
      MLX4_CORE_GEN2 = false;

      BTRFS_FS = true;
      BTRFS_FS_POSIX_ACL = true;

      CEPH_FS = true;
      CEPH_FS_POSIX_ACL = true;
    };
  });

  hardware.nitrokey.enable = true;

  networking = {
    domain = "nyantec.com";
  };

  nix = {
    settings = {
      system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ]
        ++ (map (arch: "gccarch-${arch}") (lib.systems.architectures.inferiors.znver2 ++ [ "rv64imac" "rv64imacfd" "rv64gc" "armv8-a" ]));
    };
  };

  nixpkgs.config.allowUnfreePredicate = (pkg: builtins.elem (lib.getName pkg) [ "cockroachdb" ]);

  security.acme = {
    acceptTerms = true;

    certs.${config.networking.fqdn} = {
      webroot = "/srv/www/${config.networking.fqdn}";
    };

    certs."resolve.nyantec.com" = {
      # This needs to be synchronised between servers in the cluster,
      # perhaps via Ceph?
      webroot = "/srv/www/resolve.nyantec.com";
    };

    defaults = {
      email = "ops@${config.networking.domain}";
      keyType = "rsa4096";  # preferred until Ed25519 is permitted by CAB Forum
    };
  };

  services.ceph = {
    enable = true;

    global = {
      fsid = "680c6fbc-e31c-4353-bd36-6046ceffd319";

      authClusterRequired = "cephx";
      authServiceRequired = "cephx";
      authClientRequired = "cephx";
    };

    extraConfig = {
      "ms bind ipv6" = "true";
      "ms async op threads" = "4";
      "ms async max op threads" = "24";

      "ms cluster mode" = "secure";
      "ms service mode" = "secure";
      "ms client mode" = "secure";

      "cephx cluster require signatures" = "true";
      "cephx service require signatures" = "true";
      "cephx sign messages" = "true";

      "mon osd nearfull ratio" = ".67";
    };

    mon = {
      enable = true;
      daemons = [ config.networking.hostName ];
    };

    mgr = {
      enable = true;
      daemons = [ config.networking.hostName ];
    };

    osd = {
      enable = false;

      extraConfig = {
        "bluestore cache autotune" = "true";
        "osd memory target" = "12Gi";
        "osd memory cache min" = "1Gi";

        "bluestore csum type" = "xxhash64";
        "bluestore compression algorithm" = "zstd";
        "bluestore compression mode" = "aggressive";

        "osd crush chooseleaf type" = "1";
      };
    };

    mds = {
      enable = true;
      daemons = [ config.networking.hostName ];
    };

    rgw = {
      enable = true;
      daemons = [ config.networking.hostName ];
    };   

    client = {
      enable = true;
    };  
  };

  services.cockroachdb = {
    enable = true;

    listen.address = config.networking.fqdnOrHostName;
    certsDir = pkgs.emptyDirectory;

    cache = ".05";
    maxSqlMemory = ".05";
    join = "casper.nyantec.com,melchior.nyantec.com,balthasar.nyantec.com";

    extraArgs = [
      "--cluster-name=nyantec"
      "--store=path=/var/lib/cockroachdb,attrs=ssd,size=.5"
    ];
  };

  services.gobgpd = {
    enable = true;
    settings = {
      global = {
        as = 208250;
      };

      neighbors = [
        {
          neighbor-address = "2a0f:be00:0001::";
          peer-as = 208250;
        }
      ];
    };
  };

  services.ntpd-rs = {
    enable = true;
    settings = {
      source = map (n: {
        mode = "server";
        address = "ptbtime${toString n}.ptb.de";
      }) (lib.range 1 4) ++ [
        {
          mode = "server";
          address = "alucard.nyantec.com";
        }
      ];

      server = [
        {
          listen = "[::]:123";
        }
        {
          listen = "0.0.0.0:123";
        }
      ];
    };
  };

  # static web server for ACME challenges
  services.static-web-server = {
    enable = true;
    listen = "[::]:80";
    root = "/srv/www/${config.networking.fqdn}";

    configuration = {
      advanced = {
        virtual-hosts = [
          {
            host = "resolve.nyantec.com";
            root = "/srv/www/resolve.nyantec.com";
          }
        ];
      };
    };
  };

  services.unbound = {
    enable = true;

    package = pkgs.unbound-with-systemd.override {
      withDoH = true;
      withECS = true;
      withTFO = true;
    };

    enableRootTrustAnchor = true;

    settings = {
      module-config = "subnetcache validator iterator";
      server = let
        acmeDir = config.security.acme.certs."resolve.nyantec.com".directory;
        num-threads = 16;
      in {
        inherit num-threads;

        interface = [
          "::1@53"
          "127.0.0.1@53"

          "::@443"
          "0.0.0.0@443"

          "::@853"
          "0.0.0.0@853"
        ];

        so-reuseport = true;
        ip-dscp = 20;
        outgoing-range = 8192;
        edns-buffer-size = 1472;
        udp-upstream-without-downstream = true;
        num-queries-per-thread = 4096;
        incoming-num-tcp = 1024;
        outgoing-num-tcp = 16;
        stream-wait-size = "64m";
        msg-cache-size = "128m";
        msg-cache-slabs = num-threads;
        rrset-cache-size = "256m";
        rrset-cache-slabs = num-threads;
        infra-cache-slabs = num-threads;
        key-cache-slabs = num-threads;
        cache-min-ttl = 60;
        cache-max-negative-ttl = 360;
        prefer-ip6 = true;
        tls-service-pem = "${acmeDir}/fullchain.pem";
        tls-service-key = "${acmeDir}/key.pem";
        https-port = 443;
        http-query-buffer-size = "64m";
        http-response-buffer-size = "64m";
        access-control = [ "::/0 allow" "0.0.0.0/0 allow" ];
        harden-dnssec-stripped = true;
        hide-identity = true;
        hide-version = true;
        prefetch = true;
        prefetch-key = true;
        serve-expired-client-timeout = 1800;

        # ECS
        send-client-subnet = [ "::/0" "0.0.0.0/0" ];
        max-client-subnet-ipv6 = 36;
        max-client-subnet-ipv4 = 20;
        max-ecs-tree-size-ipv6 = 128;
        max-ecs-tree-size-ipv4 = 128;
      };
    };
  };

  systemd.tmpfiles.rules = let
    inherit (config.services) cockroachdb;
  in [
    "q /var/lib/cockroachdb 0750 ${cockroachdb.user} ${cockroachdb.group} - -"
    "H /var/lib/cockroachdb - - - - +C"
  ];
}
