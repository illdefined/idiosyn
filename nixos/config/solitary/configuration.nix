{ self, ... }: { lib, config, pkgs, ... }:

with lib; let
  ports = {
    acme = 1360;
    nginx = 8080;
    synapse = 8008;
    syncv3 = 8009;
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
    inherit (self.packages.x86_64-linux) linux-hardened;
  in pkgs.linuxPackagesFor (linux-hardened.override {
    instSetArch = "x86-64-v3";
    extraConfig = linux-hardened.profile.paravirt // (with self.lib.kernel; {
      NR_CPUS = 8;

      BTRFS_FS = true;
      BTRFS_FS_POSIX_ACL = true;
    });
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
        "cache.solitary.social"
        "matrix.solitary.social"
        "media.solitary.social"
        "resolve.solitary.social"
        "syncv3.solitary.social"
      ];
    };
  };

  services.akkoma.enable = true;
  services.akkoma.extraStatic."emoji/blobs.gg" = pkgs.akkoma-emoji.blobs_gg;
  services.akkoma.extraStatic."static/terms-of-service.html" = pkgs.writeText "terms-of-service.html" ''
    <h2>Commitments</h2>
    <p>This is currently a single‐user instance and therefore I decided to formulate what would be <em>Terms of Service</em> for a multi‐user user instance as commitments. These are still incomplete and subject to expansion in the future.</p>
    <ul>
      <li>I shall observe and respect your boundaries.</li>
      <li>I shall respect your right to disengage, and support you if you wish to disengage from others.</li>
      <li>I shall accept that you may not want to be confronted with certain content and tag my posts appropriately.</li>
    </ul>
  '';

  services.akkoma.extraStatic."favicon.png" = let
    rev = "697a8211b0f427a921e7935a35d14bb3e32d0a2c";
  in pkgs.stdenvNoCC.mkDerivation {
    name = "favicon.png";

    src = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/TilCreator/NixOwO/${rev}/NixOwO_plain.svg";
      hash = "sha256-tWhHMfJ3Od58N9H5yOKPMfM56hYWSOnr/TGCBi8bo9E=";
    };

    nativeBuildInputs = with pkgs; [ librsvg ];

    dontUnpack = true;
    installPhase = ''
      rsvg-convert -o $out -w 96 -h 96 $src
    '';
  };

  services.akkoma.dist.extraFlags = [
    "-MMlp" "on"
    "-MMsco" "true"
    "-MMscs" "1024"  
  ];
  
  services.akkoma.config = let
    elixir = pkgs.formats.elixirConf { };
  in with elixir.lib; {
    ":pleroma" = {
      ":instance" = {
        name = "solitary.social";
        email = "mvs+solitary.social@nya.yt";
        notify_email = "akkoma@solitary.social";
        description = "Single‐user fediverse instance";
        instance_thumbnail = "/instance/thumbnail.avif";
        limit = 5120;
        description_limit = 5120;
        remote_limit = 131072;
        upload_limit = 160 * 1024 * 1024;
        avatar_upload_limit = 2097152;
        background_upload_limit = 4194304;
        banner_upload_limit = 4194304;
        registrations_open = false;
        account_approval_required = true;
        remote_post_retention_days = 180;
        user_bio_length = 5120;
        user_name_length = 64;
        max_account_fields = 8;
        cleanup_attachments = true;
      };

      "Pleroma.Web.Endpoint" = {
        secret_key_base._secret = "/var/lib/secrets/akkoma/key-base";
        signing_salt._secret = "/var/lib/secrets/akkoma/signing-salt";
        live_view.signing_salt._secret = "/var/lib/secrets/akkoma/liveview-salt";
      };

      "Pleroma.Emails.Mailer" = {
        enabled = true;
        adapter = mkRaw "Swoosh.Adapters.SMTP";
        relay = "localhost";
        dkim = {
          a = "ed25519-sha256";
          s = "akkoma";
          d = config.networking.fqdn;
          private_key = mkTuple [
            (mkAtom ":pem_plain")
            (mkRaw ''File.read!("/var/lib/akkoma/dkim.pem")'')
          ];
        };
      };

      ":database".rum_enabled = true;

      ":media_proxy" = {
        enabled = true;
        base_url = "https://cache.solitary.social";
        proxy_opts.redirect_on_failure = true;
        proxy_opts.max_body_length = 64 * 1024 * 1024;
      };

      ":media_preview_proxy" = {
        enabled = false;
        thumbnail_max_width = 1920;
        thumbnail_max_height = 1080;
        min_content_length = 128 * 1024;
      };

      "Pleroma.Upload".base_url = "https://media.solitary.social";

      "Pleroma.Upload".filters = map mkRaw [
        "Pleroma.Upload.Filter.Exiftool.ReadDescription"
        "Pleroma.Upload.Filter.Exiftool.StripMetadata"
        "Pleroma.Upload.Filter.Dedupe"
        "Pleroma.Upload.Filter.AnonymizeFilename"
      ];

      ":mrf".policies = map mkRaw [
        "Pleroma.Web.ActivityPub.MRF.SimplePolicy"
        "Pleroma.Web.ActivityPub.MRF.ObjectAgePolicy"
      ];

      ":mrf_simple" = {
        reject = mkMap {
          "bae.st" = "harassment";
          "brighteon.social" = "incompatible";
          "detroitriotcity.com" = "incompatible";
          "freeatlantis.com" = "incompatible";
          "freespeechextremist.com" = "incompatible";
          "gab.com" = "incompatible";
          "gleasonator.com" = "incompatible";
          "kitsunemimi.club" = "incompatible";
          "poa.st" = "incompatible";
          "seal.cafe" = "harassment";
          "social.quodverum.com" = "incompatible";
          "spinster.xyz" = "incompatible";
          "truthsocial.co.in" = "incompatible";
          "varishangout.net" = "incompatible";

          "activitypub-troll.cf" = "security";
          "misskey-forkbomb.cf" = "security";
          "repl.co" = "security";
        };

        followers_only = mkMap {
          "bitcoinhackers.org" = "annoying";
        };
      };

      ":mrf_object_age".threshold = 90 * 24 * 3600;

      ":frontend_configurations" = {
        pleroma_fe = mkMap {
          collapseMessageWithSubject = true;
          hideSiteFavicon = true;
          streaming = true;
          webPushNotifications = true;
          useStreamingApi = true;
          scopeCopy = true;
          showFeaturesPanel = false;
          subjectLineBehavior = "masto";
          alwaysShowSubjectInput = true;
          postContentType = "text/markdown";
          modalOnRepeat = true;
          minimalScopesMode = true;
          redirectRootNoLogin = "/mkl";
          translationLanguage = "EN";
        };
      };

      ":restrict_unauthenticated" = {
        timelines = mkMap {
          local = false;
          federated = true;
        };
      };

      ":translator" = {
        enabled = true;
        module = mkRaw "Pleroma.Akkoma.Translators.DeepL";
      };

      ":deepl" = {
        tier = mkAtom ":free";
        api_key._secret = "/var/lib/secrets/akkoma/deepl";
      };
    };

    ":web_push_encryption".":vapid_details" = {
      subject = "mailto:mvs+solitary.social@nya.yt";
      public_key = "BPwdJZjBeZw_ZkWU_RQ48RdPI2pHIhMAYaNJc6xut4nQRi2YSaKnfP_kLrXzRjETQh5VJsDI-azYCeEhtk-C33s";
      private_key._secret = "/var/lib/secrets/akkoma/vapid";
    };

    ":joken".":default_signer"._secret = "/var/lib/secrets/akkoma/jwt-signer";
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
      acl host-cache hdr(host),host_only cache.solitary.social
      acl host-media hdr(host),host_only media.solitary.social
      acl host-matrix hdr(host),host_only matrix.solitary.social
      acl host-syncv3 hdr(host),host_only syncv3.solitary.social
      acl host-resolve hdr(host),host_only resolve.solitary.social

      acl path-acme path_reg ^/\.well-known/acme-challenge(/.*)?$
      acl path-well-known path_beg /.well-known/
      acl path-security.txt path /.well-known/security.txt
      acl path-matrix-well-known path_reg ^/\.well-known/matrix(/.*)?$
      acl path-proxy path_reg ^/proxy(/.*)?$
      acl path-media path_reg ^/media(/.*)?$

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
      http-request set-priority-class int(2) if host-media
      http-request set-priority-class int(3) if host-cache
      http-request set-priority-class int(-2) if path-well-known
      
      http-response set-tos 20 if host-resolve  # AF22 (low‐latency, med drop)
      http-response set-tos 10 if host-matrix  # AF11 (high‐throughput, low drop)
      http-response set-tos 10 if host-syncv3  # AF11 (high‐throughput, low drop)
      http-response set-tos 12 if host-solitary  # AF12 (high‐throughput, med drop)
      http-response set-tos 14 if host-media  # AF13 (high‐throughput, high drop)
      http-response set-tos 14 if host-cache  # AF13 (high‐throughput, high drop)
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

      http-request redirect code 308 location https://media.solitary.social%[capture.req.uri,regsub("^/media","")] if host-solitary path-media
      http-request redirect code 308 location https://media.solitary.social%[capture.req.uri,regsub("^/media","")] if host-media path-media
      http-request redirect code 308 location https://cache.solitary.social%[capture.req.uri] if host-solitary path-proxy
      http-request set-path "/media%[path]" if host-media !path-acme !path-media

      use_backend acme if path-acme
      use_backend security.txt if path-security.txt
      use_backend unbound if host-resolve
      use_backend synapse if host-matrix
      use_backend syncv3 if host-syncv3
      use_backend wellknown-matrix if host-solitary path-matrix-well-known
      use_backend nginx if host-cache
      use_backend akkoma if host-solitary
      use_backend akkoma if host-media
      default_backend notfound

    backend acme
      server acme 127.0.0.1:${toString ports.acme}
      retry-on all-retryable-errors

    backend akkoma
      server akkoma /run/akkoma/socket

    backend nginx
      server nginx [::1]:${toString ports.nginx} tfo proto h2
      retry-on conn-failure empty-response response-timeout

    backend synapse
      server synapse [::1]:${toString ports.synapse}

    backend syncv3
      server syncv3 [::1]:${toString ports.syncv3}

    backend unbound
      server unbound [::1]:${toString ports.unbound} tfo ssl ssl-min-ver TLSv1.3 alpn h2 allow-0rtt ca-file ${acmeDir}/chain.pem
      retry-on conn-failure empty-response response-timeout 0rtt-rejected

    backend security.txt
      http-request return status 200 content-type text/plain file ${security-txt} if { path /.well-known/security.txt }

    backend wellknown-matrix
      http-request return status 200 content-type application/json file ${pkgs.writeText "client.json" (builtins.toJSON {
        "m.homeserver".base_url = config.services.matrix-synapse.settings.public_baseurl;
        "m.identity_server".base_url = "https://vector.im";
        "org.matrix.msc3575.proxy".url = "https://syncv3.solitary.social";
      })} if { path /.well-known/matrix/client }

      http-request return status 200 content-type application/json file ${pkgs.writeText "server.json" (builtins.toJSON {
        "m.server" = "matrix.solitary.social:443";
      })} if { path /.well-known/matrix/server }

    backend notfound
      http-request return status 404
  '';

  services.matrix-synapse.enable = true;
  services.matrix-synapse.settings = {
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

  services.nginx = {
    enable = true;

    package = pkgs.tengine;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;

    commonHttpConfig = ''
      charset utf-8;
      proxy_cache_path /var/cache/nginx/cache/akkoma_media_cache
        levels= keys_zone=akkoma_media_cache:16m max_size=16g
        inactive=1y use_temp_path=off;
      access_log off;

      set_real_ip_from ::1;
      real_ip_header X-Forwarded-For;
    '';
  };

  services.matrix-sliding-sync = {
    enable = true;
    environmentFile = "/etc/keys/sliding-sync.env";
    settings = {
      SYNCV3_BINDADDR = "[::1]:${toString ports.syncv3}";
      SYNCV3_LOG_LEVEL = "warn";
      SYNCV3_SERVER = "https://matrix.solitary.social";
    };
  };

  services.nginx.virtualHosts."cache.solitary.social" = {
    listen = [ {
      addr = "[::1]";
      port = ports.nginx;
      extraParameters = [ "http2" "fastopen=512" ];
    } ];
    locations."/" = {
      proxyPass = "http://unix:/run/akkoma/socket";
      extraConfig = ''
        proxy_cache akkoma_media_cache;
        slice 1m;
        proxy_cache_key $host$uri$is_args$args$slice_range;
        proxy_set_header Range $slice_range;

        proxy_buffering on;
        proxy_cache_lock on;
        proxy_ignore_client_abort on;

        proxy_cache_valid 200 1y;
        proxy_cache_valid 206 301 304 1h;

        proxy_cache_use_stale error timeout invalid_header updating;
      '';
    };
  };

  services.postfix = {
    enable = true;
    destination = [ ];
    localRecipients = [ ];
    networks = [ "localhost" ];
    hostname = config.networking.fqdn;
    masterConfig.smtp_inet.name = mkForce "localhost:smtp";
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;

    extraPlugins = with pkgs.postgresql_14.pkgs; [
      rum
    ];

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
      withTFO = true;
    };

    enableRootTrustAnchor = true;
  };


  services.unbound.settings = {
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
    };
  };

  systemd = let
    backendServices = [
      "akkoma.service"
      "matrix-synapse.service"
      "nginx.service"
      "unbound.service"
    ];
  in {
    services.akkoma.confinement.enable = false;
    services.akkoma.serviceConfig.BindReadOnlyPaths = [ "/var/lib/akkoma:/var/lib/akkoma:norbind" ];

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
          "/run/akkoma"
          config.security.acme.certs."solitary.social".directory
          security-txt
        ];

        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        SocketBindAllow = [ "tcp:80" "tcp:443" "udp:443" ];
        SocketBindDeny = "any";
      };
    };

    services.matrix-sliding-sync = {
      after = [ "matrix-synapse.service" ];
      serviceConfig.ReadOnlyPaths = [
        "/run/postgres"
      ];
    };

    services.nginx = {
      confinement.enable = true;
      after = [ "akkoma.service" ];
      serviceConfig = {
        BindReadOnlyPaths = [
          "/etc/hosts"
          "/etc/resolv.conf"
          "/run"
        ];

        BindPaths = [
          "/var/cache/nginx"
        ];

        ProtectSystem = mkForce false;
        SocketBindAllow = [ "tcp:${toString ports.nginx}" ];
        SocketBindDeny = "any";
        RestrictNetworkInterfaces = [ "lo" ];
      };
    };

    services.unbound = {
      wants = [ "acme-finished-${config.networking.fqdn}.service" ];
      after = [ "acme-selfsigned-${config.networking.fqdn}.service" ];
    };

    services.synapse-compress-state = {
      confinement.enable = true;

      after = [ "postgresql.service" ];
      description = "Compress Synapse state tables";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.matrix-synapse-tools.rust-synapse-compress-state}/bin/synapse_auto_compressor \
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

    timers.synapse-compress-state = {
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
