{ self, nixos-hardware, linux-hardened, ... }: { lib, config, pkgs, ... }: {
imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme-gen4
  ] ++ (with self.nixosModules; [
    default
    mimalloc
    physical
    portable
    graphical
    wireless
    fireface-ucx-2
  ]);

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" "riscv64-linux" ];
    preferStaticEmulators = true;
  };

  boot.initrd.luks.devices = {
    "luks-2fb93d4f-a0fe-4a49-9e40-3ac38ffe4d75".device = "/dev/disk/by-uuid/2fb93d4f-a0fe-4a49-9e40-3ac38ffe4d75";
    "luks-ea77e674-847f-41b8-9e1d-8b6dd08710e6".device = "/dev/disk/by-uuid/ea77e674-847f-41b8-9e1d-8b6dd08710e6";
  } |> lib.mapAttrs (_: v: v // { bypassWorkqueues = true; });

  boot.kernelParams = [
    "intel_iommu=on"
    "nouveau.config=NvGspRm=1"
    "thinkpad_acpi.fan_control=1"
  ];

  boot.kernelPackages = let
    inherit (linux-hardened.packages.x86_64-linux) thinkpad-x1-extreme-gen5;
  in pkgs.linuxPackagesFor (thinkpad-x1-extreme-gen5.override {
    extraFirmware = [
      "nvidia/ga107/acr/ucode_unload.bin"
      "nvidia/ga107/acr/ucode_asb.bin"
      "nvidia/ga107/acr/ucode_ahesasc.bin"
      "nvidia/ga107/gr/fecs_bl.bin"
      "nvidia/ga107/gr/fecs_sig.bin"
      "nvidia/ga107/gr/gpccs_bl.bin"
      "nvidia/ga107/gr/gpccs_sig.bin"
      "nvidia/ga107/gr/NET_img.bin"
      "nvidia/ga107/sec2/desc.bin"
      "nvidia/ga107/sec2/image.bin"
      "nvidia/ga107/sec2/sig.bin"
      "nvidia/ga107/sec2/hs_bl_sig.bin"
      "nvidia/ga107/nvdec/scrubber.bin"
      "nvidia/ga107/gsp/booter_load-535.113.01.bin"
      "nvidia/ga107/gsp/booter_unload-535.113.01.bin"
      "nvidia/ga107/gsp/bootloader-535.113.01.bin"
      "nvidia/ga107/gsp/gsp-535.113.01.bin"
    ];

    extraProfiles = {
      lowlatency = true;
      dm-crypt = true;
    };

    extraConfig = with linux-hardened.lib.kernel; {
      IP_MULTICAST = true;

      IPV6_ROUTER_PREF = true;
      IPV6_ROUTE_INFO = true;
      IPV6_OPTIMISTIC_DAD = true;

      ETHERNET = true;
      AQTION = true;
      USB_IPHETH = true;

      INPUT_JOYDEV = true;

      INPUT_JOYSTICK = true;

      DRM_NOUVEAU = true;
      DRM_NOUVEAU_SVM = true;
      DRM_NOUVEAU_GSP_DEFAULT = true;

      HID_LOGITECH = true;

      USB_SERIAL = true;
      USB_SERIAL_PL2303 = true;

      BTRFS_FS = true;
      BTRFS_FS_POSIX_ACL = true;
      FUSE_FS = true;
      EXFAT_FS = true;

      CRYPTO_ZSTD = true;
    };
  });

  hardware.cpu.clusters.performance = lib.range 0 11;
  hardware.cpu.clusters.efficiency = lib.range 12 19;
  hardware.cpu.intel.updateMicrocode = true;

  hardware.glasgow.enable = true;

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
  ];

  hardware.keyboard.qmk.enable = true;
  hardware.nitrokey.enable = true;

  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.utsushi ];
  };

  hardware.trackpoint = {
    enable = true;
    sensitivity = 255;
    speed = 64;
  };

  hardware.uinput.enable = true;

  environment.variables = {
    ANV_VIDEO_DECODE = "1";
  };

  i18n.supportedLocales = [
    "C.UTF-8/UTF-8"
    "en_EU.UTF-8/UTF-8"
    "en_GB.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
  ];

  ephemeral.enable = true;
  ephemeral.device = "UUID=039aa386-a39d-4329-bcf0-48936b938db1";
  ephemeral.boot.device = "PARTUUID=61c6f04c-0923-437e-860e-e88452b8e39e";
  ephemeral.boot.fsType = "vfat";
  ephemeral.subvolumes."/home" = {
    options = [ "nodev" "nosuid" ];
    extraOptions = [ "noatime" "compress=zstd" ];
  };

  networking.firewall.extraInputRules = ''
    ip6 daddr { ff02::1:3, ff02::fb } udp dport 5353 accept
    ip daddr { 224.0.0.251, 224.0.0.252 } udp dport 5353 accept

    ip6 daddr ff12::8384 udp dport 21027 accept
    ip daddr 255.255.255.255 udp dport 21027 accept

    udp dport 4992 accept
  '';

  networking.hosts = {
    "172.16.0.1" = [ "airlink.local" ];
    "192.168.178.1" = [ "fritz.box" ];
  };

  networking.firewall.allowedTCPPorts = [ 5000 22000 ];
  networking.firewall.allowedUDPPorts = [ 4992 22000 ];
  networking.firewall.allowedUDPPortRanges = [
    { from = 6001; to = 6011; }
  ];

  nix = let
    base = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    x86-64 = [ "gccarch-x86-64" "gccarch-x86-64-v2" "gccarch-x86-64-v3" ];
    riscv = [ "gccarch-rv64imac" "gccarch-rv64imacfd" "gccarch-rv64gc" ];
    aarch = [ "gccarch-armv8-a" ];
  in {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "integra.kyouma.net";
        protocol = "ssh";
        sshUser = "nix-ssh";
        maxJobs = 2;
        speedFactor = 4;
        systems = [ "aarch64-linux" ];
        supportedFeatures = base ++ aarch;
        sshKey = "/etc/keys/nix-ssh";
      }
      {
        hostName = "nokotan.kyouma.net";
        protocol = "ssh";
        sshUser = "nix-ssh";
        maxJobs = 4;
        speedFactor = 8;
        systems = [ "aarch64-linux" ];
        supportedFeatures = base ++ aarch;
        sshKey = "/etc/keys/nix-ssh";
      }
      {
        hostName = "schrodinger.kyouma.net";
        #protocol = "ssh-ng";
        sshUser = "root";
        maxJobs = 2;
        speedFactor = 4;
        systems = [ "riscv64-linux" ];
        supportedFeatures = base ++ riscv;
        sshKey = "/etc/keys/nix-ssh";
      }
      {
        hostName = "ci-builder.nyantec.com";
        protocol = "ssh";
        sshUser = "nix-ssh";
        maxJobs = 8;
        speedFactor = 16;
        systems = [ "x86_64-linux" ];
        supportedFeatures = base ++ x86-64;
        sshKey = "/etc/keys/nix-ssh";
      }
    ] ++ (lib.range 9 11 |> map (num: {
      hostName = "build-worker-${lib.fixedWidthNumber 2 num}";
      protocol = "ssh-ng";
      sshUser = "root";
      maxJobs = 2;
      speedFactor = 8;
      systems = [ "x86_64-linux" "i686-linux" "riscv64-linux" "aarch64-linux" ];
      supportedFeatures = base ++ x86-64;
      sshKey = "/etc/keys/nix-ssh";
    }));

    gc.options = lib.mkForce "--delete-older-than 90d";
    settings.system-features = base ++ x86-64 ++ riscv ++ aarch;
  };

  programs.ssh = {
    knownHosts = {
      "[build-worker-kyoumanet.fly.dev]:2200".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJUGzlilikAUfUGKXVCoTeDvPRoWUgDDkNU5WaRUBzls";
      "[build-worker-kyoumanet.fly.dev]:2201".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDL2M97UBHg9aUfjDUxzmzg1r0ga0m3/stummBVwuEAB";
      "[build-worker-kyoumanet.fly.dev]:2202".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOTwVKL0P0chPM2Gz23rbT94844+w1CGJdCaZdzfjThz";
      "[build-worker-kyoumanet.fly.dev]:2203".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAjy2eZGJQeAYy0+fLgW9jiS0jVY2LInY0NDMnzCvvKp";
      "[build-worker-kyoumanet.fly.dev]:2204".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN72OyD9LYy4hq0WZ7ie5RPV+G54UreEJiA/RubjGoe9";
      "[build-worker-kyoumanet.fly.dev]:2205".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICNh1o1I98XrI2XmOI6Q0aHPfyLCIQwKkKOxGUUeXL9v";
      "[build-worker-kyoumanet.fly.dev]:2206".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGf0kxGgwOG9KhUhvxxTSiQC5YikrzZXKDgSpBw33qN4";
      "[build-worker-kyoumanet.fly.dev]:2207".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL9z95a6Fn/dB+iNigEYpuJdBnBwCkIZYaKHcFbGP+RY";
      "[build-worker-kyoumanet.fly.dev]:2208".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAk+FNMhTfAVqk3MfLp4QiG/i5ti53DlpnC0q+sOvU9O";
      "[build-worker-kyoumanet-cdg.fly.dev]:2209".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJGlQD/3fLn/Kyb7v0RIycHRcArGi75jURj803EMpW0S";
      "[build-worker-kyoumanet-cdg.fly.dev]:2210".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMQm1FSGBGdCR5f8MvBvdKM0M4yIQVnH1po7hHO5T1qz";
      "[build-worker-kyoumanet-cdg.fly.dev]:2211".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINlH+v2ZlcDQY3itw4b7aRbwRTqDsTE0R5Ua3vF0VaGr";
      "ci-builder.nyantec.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKU/sFJB0ksfoh8Is9mPWENJgcTXxP3/rjKHFjCLNv5";
      "integra.kyouma.net".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBwEQiSfaDrUAwgul4mktusBPcIVxI4pLNDh9DPopVU";
      "nokotan.kyouma.net".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4QwwbDcIYr64gp9WM+gNX9hr7vqCeVXdr0DmldsNX7";
      "schrodinger.kyouma.net".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKo7vZ6lS1wx76YsbAdhOsGcc20YMAW52ep8SZ/FCHDp";
      "zh1830.rsync.net".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJtclizeBy1Uo3D86HpgD3LONGVH0CJ0NT+YfZlldAJd";
    };

    extraConfig = lib.range 0 11 |> map (num: ''
      Host build-worker-${lib.fixedWidthNumber 2 num}
        Hostname build-worker-kyoumanet${lib.optionalString (num > 8) "-cdg"}.fly.dev
        Port ${toString (2200 + num)}
    '') |> lib.concatStrings;
  };

  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark-qt;
    dumpcap.enable = true;
    usbmon.enable = true;
  };

  services.beesd.filesystems.root = {
    spec = "UUID=039aa386-a39d-4329-bcf0-48936b938db1";
    hashTableSizeMB = 1024;
    verbosity = "crit";
  };

  services.fprintd.enable = true;

  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    brlaser
  ];

  services.udev = {
    packages = with pkgs; [ utsushi ];
    extraRules = lib.concatStringsSep ", " [
      ''ACTION=="add|change"''
      ''SUBSYSTEM=="video4linux"''
      ''ATTRS{idVendor}=="0x046d"''
      ''ATTRS{idProduct}=="0x085e"''
      ''ATTR{index}=="0"''
      ''RUN+="${pkgs.v4l-utils}/bin/v4l2-ctl --device $devnode --set-ctrl pan_absolute=10800,tilt_absolute=-36000,zoom_absolute=150"''
    ];
  };

  services.usbmuxd.enable = true;

  systemd.services."beesd@root" = {
    bindsTo = [ "power-external.target" ];
    serviceConfig = {
      IOSchedulingClass = "idle";
      IOSchedulingPriority = lib.mkForce null;
      CPUWeight = lib.mkForce "idle";
    };
  };

  users.users.nil.hashedPasswordFile = "/etc/keys/users/nil";
  users.users.nil.extraGroups = [
    "audio" "input" "uinput" "plugdev" "video" "render" "scanner" "nitrokey" "wireshark"
  ];
}
