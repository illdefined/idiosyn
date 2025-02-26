{ self, linux-hardened, ... }: { lib, config, pkgs, ... }:

with lib; let
  ports = {
    acme = 1360;
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

  nixpkgs.localSystem.system = "aarch64-linux";

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  boot.kernelPackages = let
    inherit (linux-hardened.packages.aarch64-linux) paravirt;
  in pkgs.linuxPackagesFor (paravirt.override {
    instSetArch = "neoverse-n1";
    extraConfig = with linux-hardened.lib.kernel; {
      NR_CPUS = 6;

      BTRFS_FS = true;
      BTRFS_FS_POSIX_ACL = true;

      CRYPTO_ZSTD = true;
    };
  });

  environment.etc."machine-id".text = "1c97ae368741530de77aad42b5a6ae42";

  ephemeral.device = "UUID=07a91cc3-4dd4-48e6-81d7-eb5d31fcf720";
  ephemeral.boot.device = "UUID=BA7E-F0B5";
  ephemeral.boot.fsType = "vfat";

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

  services.conduwuit = {
    enable = true;
    package = pkgs.conduwuit.override {
      enableJemalloc = false;
    };

    settings.global = {
      server_name = "solitary.social";
      well_known = {
        client = "https://matrix.solitary.social";
        server = "matrix.solitary.social:443";
      };

      ip_lookup_strategy = 4;

      unix_socket_path = "/run/conduwuit/socket";
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
      use_backend conduwuit if host-matrix
      default_backend notfound

    backend acme
      server acme 127.0.0.1:${toString ports.acme}
      retry-on all-retryable-errors

    backend conduwuit
      server conduwuit /run/conduwuit/socket

    backend unbound
      server unbound [::1]:${toString ports.unbound} tfo ssl ssl-min-ver TLSv1.3 alpn h2 allow-0rtt ca-file ${acmeDir}/chain.pem
      retry-on conn-failure empty-response response-timeout 0rtt-rejected

    backend security.txt
      http-request return status 200 content-type text/plain file ${security-txt} if { path /.well-known/security.txt }

    backend notfound
      http-request return status 404
  '';

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
      "conduwuit.service"
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
          config.services.conduwuit.settings.global.unix_socket_path
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
  };

  users.users.${config.services.haproxy.user}.extraGroups = [
    config.security.acme.certs.${config.networking.fqdn}.group
    config.services.conduwuit.group
  ];

  users.users.${config.services.unbound.user}.extraGroups = [ config.security.acme.certs.${config.networking.fqdn}.group ];
}
