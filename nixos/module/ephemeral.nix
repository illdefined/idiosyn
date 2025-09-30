{ ... }: { config, lib, pkgs, ...}:

let
  cfg = config.ephemeral;

  device = lib.mkOption {
    type = lib.types.nonEmptyStr;
    description = "Device to mount.";
  };

  options = lib.mkOption {
    type = with lib.types; listOf nonEmptyStr;
    readOnly = true;
    description = "Options used to mount the file system.";
  };

  extraOptions = lib.mkOption {
    type = with lib.types; listOf nonEmptyStr;
    default = [ ];
    description = "Additional options used to mount the file system.";
  };

  filesystem = {
    options = {
      inherit device options extraOptions;
      fsType = lib.mkOption {
        type = lib.types.nonEmptyStr;
        description = "Type of the file system.";
      };
    };
  };

  tmpfs = {
    options = {
      inherit options extraOptions;
      name = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "none";
        description = "Name of the file system.";
      };

      size = lib.mkOption {
        type = with lib.types; either nonEmptyStr ints.positive;
        description = "Size of the file system.";
      };

      mode = lib.mkOption {
        type = lib.types.nonEmptyStr;
        description = "Initial permissions of the root directory.";
      };

      uid = lib.mkOption {
        type = with lib.types; either nonEmptyStr ints.unsigned;
        default = 0;
        description = "Initial user ID of the root directory";
      };

      gid = lib.mkOption {
        type = with lib.types; either nonEmptyStr ints.unsigned;
        default = 0;
        description = "Initial group ID of the root directory";
      };
    };
  };

  subvol = {
    options = {
      inherit options extraOptions;
      subvolume = lib.mkOption {
        type = with lib.types; nullOr nonEmptyStr;
        default = null;
        description = "Source path of the subvolume.";
      };
    };
  };

  ephemeralDefaults = {
    "/" = {
      size = "64m";
      mode = "755";
      uid = 0;
      gid = 0;
      options = [ "nodev" "noexec" "nosuid" ];
      extraOptions = [ ];
    };
    "/run/nix" = {
      size = "80%";
      mode = "1775";
      uid = 0;
      gid = "nixbld";
      options = [ "nodev" "nosuid" ];
      extraOptions = [ ];
    };
    "/tmp" = {
      size = "256m";
      mode = "1777";
      uid = 0;
      gid = 0;
      options = [ "nodev" "noexec" "nosuid" ];
      extraOptions = [ ];
    };
  };

  subvolumeDefaults = {
    "/etc/keys" = {
      options = [ "nodev" "noexec" "nosuid" ];
    };
    "/etc/credstore" = {
      options = [ "nodev" "noexec" "nosuid" ];
    };
    "/etc/credstore.encrypted" = {
      options = [ "nodev" "noexec" "nosuid" ];
    };
    "/nix" = {
      options = [ "nodev" "nosuid" ];
    };
    "/var" = {
      options = [ "nodev" "noexec" "nosuid" ];
    };
  } |> lib.mapAttrs (name: subvol: subvol // {
    extraOptions = [ "lazytime" "autodefrag" "compress=zstd:1" ];
  });
in {
  options = {
    ephemeral = {
      enable = lib.mkEnableOption "ephemeral filesystem";

      device = lib.mkOption {
        type = lib.types.nonEmptyStr;
        description = "Persistent btrfs device.";
      };

      boot = {
        inherit device;

        fsType = lib.mkOption {
          type = lib.types.nonEmptyStr;
        };

        options = lib.mkOption {
          inherit (options) type readOnly description;
          default = [ "nodev" "noexec" "nosuid" ]
            ++ lib.optionals (cfg.boot.fsType == "vfat") [ "fmask=0137" "dmask=022" ]
            ++ lib.optionals (builtins.match "ext[34]" cfg.boot.fsType != null) [ "data=journal" ];
        };

        extraOptions = lib.mkOption {
          inherit (extraOptions) type description;
          default = [ "lazytime" ];
        };
      };

      ephemeral = lib.mkOption {
        type = with lib.types; attrsOf (submodule tmpfs);
        description = "Ephemeral filesystems.";
        default = ephemeralDefaults;
      };

      subvolumes = lib.mkOption {
        type = with lib.types; attrsOf (submodule subvol);
        description = "Persistent subvolumes.";
        default = subvolumeDefaults;
        example = {
          "/home" = {
            options = [ "nodev" "noexec" "nosuid" ];
            extraOptions = [ "lazytime" "compress=zstd:1" ];
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.availableKernelModules = [ "zstd" ];
    boot.supportedFilesystems = [ "btrfs" ];

    environment.etc = lib.mkMerge [
      {
        machine-id.source = lib.mkDefault "/etc/keys/machine-id";
        secureboot.source = lib.mkDefault "/etc/keys/secureboot";
      }
      (lib.mkIf (with config.system.etc.overlay; enable && !mutable) ((subvolumeDefaults // cfg.subvolumes)
        |> lib.filterAttrs (path: _: lib.hasPrefix "/etc/" path)
        |> lib.mapAttrs' (path: _: {
          name = "${lib.removePrefix "/etc/" path}/.keep";
          value = {
            mode = "0000";
            source = pkgs.emptyFile;
          };
        })))
    ];

    fileSystems = {
        "/boot" = {
          device = cfg.boot.device;
          fsType = cfg.boot.fsType;
          options = cfg.boot.options ++ cfg.boot.extraOptions;
        };
      } //
      (builtins.mapAttrs (key: val: {
        fsType = "tmpfs";
        options = val.options ++ val.extraOptions
          ++ [
            "strictatime"
            "size=${toString val.size}"
            "mode=${val.mode}"
            "uid=${toString val.uid}"
            "gid=${toString val.gid}"
            "huge=within_size"
          ];
      }) (ephemeralDefaults // cfg.ephemeral)) //
      (builtins.mapAttrs (key: val: {
        device = cfg.device;
        fsType = "btrfs";
        options = val.options ++ val.extraOptions
          ++ [ "subvol=${if (val ? subvolume && val.subvolume != null) then val.subvolume else key}" ];
        neededForBoot = true;
      }) (subvolumeDefaults // cfg.subvolumes));

    nix.settings.build-dir = lib.mkDefault "/run/nix";
    systemd.services.nix-daemon.environment.TMPDIR = lib.mkDefault "/run/nix";

    systemd.tmpfiles.settings.ephemeral = {
      "/etc/keys".z = {
        mode = "0751";
        user = "root";
        group = "root";
      };
      "/etc/credentials".z = {
        mode = "0750";
        user = "root";
        group = "root";
      };
      "/etc/credentials.encrypted".z = {
        mode = "0750";
        user = "root";
        group = "root";
      };
      "/run/nix".D = {
        mode = "1775";
        user = "root";
        group = "nixbld";
        age = "~1d";
      };
    };
  };
}
