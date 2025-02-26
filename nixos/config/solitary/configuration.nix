{ self, linux-hardened, ... }: { lib, config, pkgs, ... }:

with lib; let
  ports = {
    acme = 1360;
    synapse = 8008;
    unbound = 8484;
  };

  security-txt = pkgs.writeText "security.txt" ''
    -----BEGIN SSH SIGNED MESSAGE-----
    Canonical: https://solitary.social/.well-known/security.txt
    Contact: mailto:mvs@nya.yt
    Encryption: data:application/x-age-public-key,age1dexxdduwl37hsfdxde6le0satatrfv4geva0cxt8qqw3n46vgavsanuewp
    Preferred-Languages: en, de
    -----END SSH SIGNED MESSAGE-----
    -----BEGIN SSH SIGNATURE-----
    U1NIU0lHAAAAAQAAAEoAAAAac2stc3NoLWVkMjU1MTlAb3BlbnNzaC5jb20AAAAgJzM8dH
    Bj0wDAMaVwHRCAw4mNyksmFVTdyi+tb1EFLrYAAAAEc3NoOgAAAARmaWxlAAAAAAAAAAZz
    aGE1MTIAAABnAAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAQNoPCgqiDsNs8+
    PyhjKdWF3P0TkA3gXH9fRSCRJvlMTz5hlhusz6ipEnKb8q/fYIwiuPsIJQseevg1kFZTe3
    vAoBAAADlA==
    -----END SSH SIGNATURE-----
  '';
in {
  imports = with self.nixosModules; [
    default
    headless
    acme-ocsp
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };

  boot.kernelParams = [
    "hugepagesz=1G" "hugepages=1"
  ];

  boot.kernelPackages = let
    inherit (linux-hardened.packages.x86_64-linux) paravirt;
  in pkgs.linuxPackagesFor (paravirt.override {
    instSetArch = "x86-64-v3";
    extraConfig = with linux-hardened.lib.kernel; {
      NR_CPUS = 8;

      BTRFS_FS = true;
      BTRFS_FS_POSIX_ACL = true;

      CRYPTO_ZSTD = true;
    };
  });

  environment.etc."machine-id".text = "1c97ae368741530de77aad42b5a6ae42";

  ephemeral.device = "UUID=07a91cc3-4dd4-48e6-81d7-eb5d31fcf720";
  ephemeral.boot.device = "UUID=24c72e0c-b467-4def-a641-ae09100465f0";
  ephemeral.boot.fsType = "ext4";

  i18n.supportedLocales = [ "C.UTF-8/UTF-8" "en_EU.UTF-8/UTF-8" "en_GB.UTF-8/UTF-8" ];

  networking = {
    hostName = "solitary";
    domain = "social";
    firewall.allowedTCPPorts = [ 22 80 443 853 ];
    firewall.allowedUDPPorts = [ 443 ];
  };

  security.acme = {
    certs.${config.networking.fqdn} = {
      email = "mvs@nya.yt";
      listenHTTP = "127.0.0.1:${toString ports.acme}";
      reloadServices = [ "haproxy.service" "unbound.service" ];
      extraDomainNames = [
        "matrix.solitary.social"
        "resolve.solitary.social"
      ];
    };
  };

  services.haproxy.enable = true;
  services.haproxy.config =
  let
    ciphers = "ECDHE+CHACHA20:ECDHE+AESGCM";
    cipherSuites = "TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256";
    options = "ssl-min-ver TLSv1.2 no-tls-tickets";
    acmeDir = config.security.acme.certs.${config.networking.fqdn}.directory;
    compTypes = [
      "application/javascript"
      "application/json"
      "image/svg+xml"
      "text/css"
      "text/html"
      "text/javascript"
      "text/plain"
    ];
  in ''
    global
      expose-experimental-directives

      log stderr format short alert notice

      maxconn 9216
      nbthread 2
      cpu-map auto:1/all 0-63

      ssl-default-bind-ciphers ${ciphers}
      ssl-default-bind-ciphersuites ${cipherSuites}
      ssl-default-bind-options prefer-client-ciphers ${options}

      ssl-default-server-ciphers ${ciphers}
      ssl-default-server-ciphersuites ${cipherSuites}
      ssl-default-server-options ${options}

    defaults
      log global
      mode http
      option abortonclose
      option checkcache
      option forwardfor
      option http-keep-alive
      option http-restrict-req-hdr-names reject
      option httpchk
      option splice-auto
      option tcp-smart-connect

      timeout connect 5s
      timeout client 30s
      timeout http-request 5s
      timeout client-fin 5s
      timeout tunnel 1h
      timeout server 30s
      timeout check 5s

    cache default
      total-max-size 16
      max-age 240

    frontend http
      bind :::443 v4v6 defer-accept tfo ssl crt ${acmeDir}/full.pem allow-0rtt alpn h2,http/1.1
      bind quic6@:443 v4v6 ssl crt ${acmeDir}/full.pem allow-0rtt alpn h3
      bind :::80 v4v6 defer-accept tfo

      acl replay-safe method GET HEAD OPTIONS req.body_size eq 0

      acl host-solitary hdr(host),host_only solitary.social
      acl host-matrix hdr(host),host_only matrix.solitary.social
      acl host-resolve hdr(host),host_only resolve.solitary.social

      acl path-acme path_reg ^/\.well-known/acme-challenge(/.*)?$
      acl path-well-known path_beg /.well-known/
      acl path-security.txt path /.well-known/security.txt
      acl path-matrix-well-known path_reg ^/\.well-known/matrix(/.*)?$

      #http-request normalize-uri fragment-strip
      #http-request normalize-uri path-strip-dot
      #http-request normalize-uri path-strip-dotdot full
      #http-request normalize-uri path-merge-slashes
      #http-request normalize-uri percent-decode-unreserved strict
      #http-request normalize-uri percent-to-uppercase strict
      #http-request normalize-uri query-sort-by-name

      http-request redirect scheme https code 301 unless { ssl_fc } or path-acme
      http-request wait-for-handshake unless replay-safe

      http-request set-priority-class int(-1) if host-resolve
      http-request set-priority-class int(1) if host-solitary
      http-request set-priority-class int(-2) if path-well-known
      
      http-response set-tos 20 if host-resolve  # AF22 (low‐latency, med drop)
      http-response set-tos 10 if host-matrix  # AF11 (high‐throughput, low drop)
      http-response set-tos 12 if host-solitary  # AF12 (high‐throughput, med drop)
      http-response set-tos 20 if path-well-known  # AF22 (low‐latency, med drop)

      http-request cache-use default
      http-request set-header X-Forwarded-Proto %[ssl_fc,iif(https,http)]

      http-response set-header Alt-Svc "h3=\":443\"; ma=7776000; persist=1, h2=\":443\"; ma=7776000; persist=1"
      http-response set-header Cross-Origin-Embedder-Policy require-corp unless { res.hdr(Cross-Origin-Embedder-Policy) -m found }
      http-response set-header Cross-Origin-Opener-Policy same-site unless { res.hdr(Cross-Origin-Opener-Policy) -m found }
      http-response set-header Cross-Origin-Resource-Policy same-site unless { res.hdr(Cross-Origin-Resource-Policy) -m found }
      http-response set-header Content-Security-Policy "default-src 'self'; frame-ancestors 'none'" unless { res.hdr(Content-Security-Policy) -m found }
      http-response set-header Referrer-Policy same-origin unless { res.hdr(Referrer-Policy) -m found }
      http-response set-header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload"
      http-response set-header X-Frame-Options DENY
      http-response set-header X-Content-Type-Options nosniff
      http-response set-header X-XSS-Protection "1; mode=block"

      compression algo gzip
      compression type ${concatStringsSep " " compTypes}
      http-response cache-store default

      use_backend acme if path-acme
      use_backend security.txt if path-security.txt
      use_backend unbound if host-resolve
      use_backend synapse if host-matrix
      use_backend wellknown-matrix if host-solitary path-matrix-well-known
      default_backend notfound

    backend acme
      server acme 127.0.0.1:${toString ports.acme}
      retry-on all-retryable-errors

    backend synapse
      server synapse [::1]:${toString ports.synapse}

    backend unbound
      server unbound [::1]:${toString ports.unbound} tfo ssl ssl-min-ver TLSv1.3 alpn h2 allow-0rtt ca-file ${acmeDir}/chain.pem
      retry-on conn-failure empty-response response-timeout 0rtt-rejected

    backend security.txt
      http-request return status 200 content-type text/plain file ${security-txt} if { path /.well-known/security.txt }

    backend wellknown-matrix
      http-request return status 200 content-type application/json file ${pkgs.writeText "client.json" (builtins.toJSON {
        "m.homeserver".base_url = config.services.matrix-synapse.settings.public_baseurl;
        "m.identity_server".base_url = "https://vector.im";
      })} if { path /.well-known/matrix/client }

      http-request return status 200 content-type application/json file ${pkgs.writeText "server.json" (builtins.toJSON {
        "m.server" = "matrix.solitary.social:443";
      })} if { path /.well-known/matrix/server }

    backend notfound
      http-request return status 404
  '';

  services.matrix-synapse = {
    enable = true;
    withJemalloc = false;
    settings = {
      database_type = "psycopg2";
      server_name = "solitary.social";
      public_baseurl = "https://matrix.solitary.social/";
      default_identity_server = "https://vector.im";
      enable_registration = false;

      listeners = [ {
        bind_addresses = [ "::1" ];
        port = ports.synapse;
        type = "http";
        tls = false;
        x_forwarded = true;

        resources = [ {
          names = [ "client" "federation" ];
          compress = true;
        } ];
      } ];

      log_config = ./log_config.yaml;
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;

    extensions = with pkgs.postgresql_16.pkgs; [
      rum
    ];

    settings = {
      max_connections = 128;

      shared_buffers = "768MB";
      huge_pages = "try";
      huge_page_size = "2MB";
      work_mem = "16MB";

      effective_io_concurrency = 128;

      wal_compression = "zstd";
    };

    initialScript = pkgs.writeText "init.psql" ''
      CREATE ROLE "matrix-synapse";
      CREATE DATABASE "matrix-synapse" OWNER "matrix-synapse"
        TEMPLATE template0
        ENCODING 'utf8'
        LOCALE 'C';
    '';
  };

  services.unbound = {
    enable = true;

    package = pkgs.unbound-with-systemd.override {
      withDoH = true;
      withECS = true;
      withTFO = true;
    };

    enableRootTrustAnchor = true;
  };


  services.unbound.settings = {
    module-config = ''"subnetcache validator iterator"'';
    server = let
      acmeDir = config.security.acme.certs.${config.networking.fqdn}.directory;
      num-threads = 2;
    in {
      inherit num-threads;

      interface = [
        "::1@53"
        "127.0.0.1@53"

        "::1@${toString ports.unbound}"

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
      https-port = ports.unbound;
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

  systemd = let
    backendServices = [
      "matrix-synapse.service"
      "unbound.service"
    ];
  in {
    services.haproxy = {
      confinement.enable = false;

      wants = [ "acme-finished-${config.networking.fqdn}.service" ]
        ++ backendServices;
      after = [ "acme-selfsigned-${config.networking.fqdn}.service" ]
        ++ backendServices;
      before = [ "acme-${config.networking.fqdn}.service" ];

      reloadTriggers = [ "${config.security.acme.certs.${config.networking.fqdn}.directory}/cert.ocsp" ];

      serviceConfig = {
        BindReadOnlyPaths = [
          "/etc/haproxy.cfg"
          "/etc/hosts"
          "/etc/resolv.conf"
          config.security.acme.certs."solitary.social".directory
          security-txt
        ];

        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        SocketBindAllow = [ "tcp:80" "tcp:443" "udp:443" ];
        SocketBindDeny = "any";
      };
    };

    services.unbound = {
      wants = [ "acme-finished-${config.networking.fqdn}.service" ];
      after = [ "acme-selfsigned-${config.networking.fqdn}.service" ];
    };

    services.synapse-state-compress = {
      confinement.enable = true;

      after = [ "postgresql.service" ];
      description = "Compress Synapse state tables";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.rust-synapse-state-compress}/bin/synapse_auto_compressor \
            -p "host=/run/postgresql \
            user=${config.services.matrix-synapse.settings.database.args.database} \
            dbname=${config.services.matrix-synapse.settings.database.args.database}" \
            -c 512 -n 128
        '';
        User = "matrix-synapse";
        WorkingDirectory = "/tmp";

        BindReadOnlyPaths = [
          "/run/postgresql"
        ];

        ProtectProc = "noaccess";
        ProcSubset = "pid";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateIPC = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;

        RestrictAddressFamilies = [ "AF_UNIX" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;

        CapabilityBoundingSet = null;
        NoNewPrivileges = true;
        SystemCallFilter = [ "@system-service" "~@resources" "~@privileged" ];
        SystemCallArchitectures = "native";

        UMask = "0077";
      };
    };

    timers.synapse-state-compress = {
      enable = true;
      description = "Compress Synapse state tables daily";
      timerConfig = {
        OnCalendar = "04:00";
      };

      wantedBy = [ "timers.target" ];
    };
  };

  users.users.${config.services.haproxy.user}.extraGroups = [ config.security.acme.certs.${config.networking.fqdn}.group ];
  users.users.${config.services.unbound.user}.extraGroups = [ config.security.acme.certs.${config.networking.fqdn}.group ];
}
