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
    profiles = {
      physical = true;
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

  nix = {
    settings = {
      system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ]
        ++ (map (arch: "gccarch-${arch}") (lib.systems.architectures.inferiors.znver2 ++ [ "rv64imac" "rv64imacfd" "rv64gc" "armv8-a" ]));
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
}
