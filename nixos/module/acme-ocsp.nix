{ ... }: { config, pkgs, lib, ...}:

let
  cfg = config.security.acme;

  script = pkgs.writeShellApplication {
    name = "ocsp-query";
    runtimeInputs = with pkgs; [ openssl ];
    text = ''
      cd "$1"

      tmp="$(mktemp ocsp.der.XXXXXXXXXX)"
      trap 'rm -f "$tmp"' EXIT TERM

      url="$(openssl x509 -in cert.pem -noout -ocsp_uri)"
      openssl ocsp -issuer chain.pem -cert cert.pem -url "$url" -respout "$tmp"

      chown "$(id -u):$(id -g)" "$tmp"
      chmod 644 "$tmp"
      mv "$tmp" ocsp.der

      ln -s -f ocsp.der full.ocsp
    '';
  };
in {
  options.security.acme.ocspTimer = lib.mkOption {
    type = with lib.types; nullOr nonEmptyStr;
    default = "daily";
    description = "Realtime (wall clock) timer for regular OCSP queries.";
  };

  config = lib.mkIf (cfg.ocspTimer != null) {
    systemd.services = lib.mapAttrs' (cert: conf: lib.nameValuePair "ocsp-${cert}" {
      description = "Query OCSP endpoint for ${cert}";
      after = [ "network.target" "network-online.target" "acme-${cert}.service" ];
      wants = [ "network.target" "network-online.target" "acme-${cert}.service" ];

      confinement.enable = true;
      confinement.packages = with pkgs; [ openssl ];

      serviceConfig = {
        Type = "oneshot";

        User = "acme";
        Group = conf.group;
        UMask = "0022";

        BindPaths = [ conf.directory ];

        ExecStart = "${script}/bin/ocsp-query ${lib.escapeShellArg conf.directory}";

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
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        CapabilityBoundingSet = null;
        NoNewPrivileges = true;
        SystemCallFilter = [ "@system-service" "~@privileged" "@chown" ];
        SystemCallArchitectures = "native";
        DeviceAllow = null;
        DevicePolicy = "closed";
        SocketBindDeny = "any";
      };
    }) cfg.certs;

    systemd.timers = lib.mapAttrs' (cert: conf: lib.nameValuePair "ocsp-${cert}" {
      description = "Query OCSP endpoint for ${cert} regularly";
      timerConfig.OnCalendar = cfg.ocspTimer;
    }) cfg.certs;
  };
}
