{ self, ... }: { config, lib, pkgs, ... }@args:
let
  inherit (lib)
    optionals
    getLib
    getExe;

  osConfig = args.osConfig or { };
  cfg = config.services.ausweisapp;

  fontsConf = pkgs.makeFontsConf {
    fontDirectories = osConfig.fonts.packages;
    impureFontDirectories = [ ];
    includes = [ ];
  };

  fontsCache = pkgs.makeFontsCache {
    fontDirectories = osConfig.fonts.packages;
  };

  mimalloc = pkgs.mimalloc.override {
    secureBuild = true;
  } |> getLib;

  mesa = getLib cfg.mesaPackage;
in {
  options.services.ausweisapp = {
    enable = lib.mkEnableOption "AusweisApp2";
    package = lib.mkOption {
      type = lib.types.package;
      description = "The AusweisApp2 package to use.";
      default = pkgs.ausweisapp.overrideAttrs (prevAttrs: {
        hardeningEnable = prevAttrs.hardeningEnable or [ ]
          ++ [ "pie" "trivialautovarinit" ];
      });
    };

    mesaPackage = lib.mkOption {
      type = lib.types.package;
      description = "The mesa package to use.";
      default = osConfig.hardware.graphics.package or pkgs.mesa;
    };

    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      description = "Extra packages to include in the AusweisApp2 closure.";
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services = {
      ausweisapp-dbus-proxy = {
        Unit = {
          Description = "DBus proxy for AusweisApp eID client";
        };

        Service = {
          ExecStart = [
            (getExe pkgs.xdg-dbus-proxy)
            "\${DBUS_SESSION_BUS_ADDRESS}"
            "\${RUNTIME_DIRECTORY}/bus"
            "--filter"
          ] ++ map (name: [ "--see=${name}" "--talk=${name}" ]) [
            "org.freedesktop.Notifications"
            "org.kde.StatusNotifierWatcher"
          ] |> toString;

          RuntimeDirectory = "ausweisapp";
          Slice = "app-efficiency.slice";
        };
      };

      ausweisapp = {
        Unit = {
          Description = "AusweisApp eID client";
          Wants = [ "ausweisapp-dbus-proxy.service" ];
          After = [
            "graphical-session.target"
            "tray.target"
            "ausweisapp-dbus-proxy.service"
          ];
        };

        Service = {
          ExecStart = "${getExe cfg.package} --no-logfile";

          Environment = [
            "LD_PRELOAD=${mimalloc}/lib/libmimalloc-secure.so"

            "LD_LIBRARY_PATH=${mesa}/lib"
            "__EGL_VENDOR_LIBRARY_DIRS=${mesa}/share/glvnd/egl_vendor.d"
            "LIBGL_ALWAYS_SOFTWARE=true"
            "LIBGL_DRIVERS_PATH=${mesa}/lib/dri"

            "FONTCONFIG_FILE=${fontsConf}"

            "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/ausweisapp/bus"
          ] ++ optionals (osConfig ? i18n.glibcLocales) [
            "LOCALE_ARCHIVE=${osConfig.i18n.glibcLocales}/lib/locale/locale-archive"
          ];

          ConfigurationDirectory = "AusweisApp";
          CacheDirectory = "AusweisApp";

          ConfigurationDirectoryMode = "0700";
          CacheDirectoryMode = "0700";

          CapabilityBoundingSet = [ ];
          AmbientCapabilities = [ ];
          NoNewPrivileges = true;
          SecureBits = toString [ "noroot" "noroot-locked" ];

          TemporaryFileSystem = toString [
            "/:ro,nodev,noexec,nosuid"
            "%h:nodev,noexec,nosuid"
          ];

          MountAPIVFS = true;

          BindReadOnlyPaths = [
            # basic system configuration
            "/etc/localtime"

            # graphical environment
            "%t/ausweisapp"
            "-%t/wayland-0"
            "-%t/wayland-1"
          ] ++ optionals (osConfig ? fonts.packages) [
            fontsConf
            "${fontsCache}:%C/fontconfig"
          ] ++ [
            # DNS resolver
            "/etc/resolv.conf"

            # Smart cards via PC/SC
            "-/run/pcscd"
          ] |> toString;

          PrivateTmp = "disconnected";
          PrivateDevices = true;
          PrivateIPC = true;
          PrivateUsers = "self";
          ProtectClock = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = "strict";

          RestrictAddressFamilies = toString [
            "AF_UNIX"  # graphical environment
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"  # udev device enumeration
          ];

          RestrictFileSystems = toString [
            "~@privileged-api"
            "~@security"
          ];

          RestrictNamespaces = true;

          LockPersonality = true;
          RestrictSUIDSGID = true;

          SystemCallFilter = toString [ "@system-service" "@sandbox" ];

          SystemCallErrorNumber = "EPERM";
          SystemCallArchitectures = "native";

          SocketBindAllow = toString [ "24727" ];
          SocketBindDeny = "any";

          Slice = "app-efficiency.slice";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };

    xdg.configFile."systemd/user/ausweisapp.service.d/10-closure.conf".source = pkgs.runCommand "10-closure.conf" {
      __structuredAttrs = true;
      preferLocalBuild = true;
      exportReferencesGraph.closure = [
        cfg.package

        mimalloc
        mesa

        (osConfig.i18n.glibcLocales or null)
      ] ++ osConfig.fonts.packages or [ ]
        ++ cfg.extraPackages;
    } ''
      echo "[Service]" >"$out"

      ${lib.getExe pkgs.jaq} -r '.closure[].path' "$NIX_ATTRS_JSON_FILE" | while read path; do
        if [ -L "$path" ]; then
          echo "BindReadOnlyPaths=$(${lib.getExe' pkgs.coreutils "readlink"} -e "$path"):$path" >>"$out"
        else
          echo "BindReadOnlyPaths=$path" >>"$out"
        fi
      done
    '';
  };
}
