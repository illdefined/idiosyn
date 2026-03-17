{ self, linux-hardened, ... }: { lib, config, pkgs, ... }: {
imports = with self.nixosModules; [
    default
    mimalloc
    physical
    portable
    graphical
    wireless
    fireface-ucx-2
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  boot.binfmt = {
    emulatedSystems = [ "riscv64-linux" "x86_64-linux" ];
    preferStaticEmulators = true;
  };

  boot.initrd.luks.devices = {
    "luks-f20b114d-c519-4ded-b7db-a4641f948e9e" = {
      device = "/dev/disk/by-uuid/f20b114d-c519-4ded-b7db-a4641f948e9e";
      allowDiscards = true;
      bypassWorkqueues = true;
    };
  };

  boot.kernelPackages = let
    inherit (linux-hardened.packages.aarch64-linux) thinkpad-t14s-gen6-x1e;
  in pkgs.linuxPackagesFor (thinkpad-t14s-gen6-x1e.override {
    extraProfiles = {
      lowlatency = true;
      dm-crypt = true;
    };

    extraConfig = {
      ETHERNET = true;
      AQTION = true;
      USB_IPHETH = true;

      INPUT_JOYDEV = true;

      INPUT_JOYSTICK = true;

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

  hardware.deviceTree = {
    enable = true;
    name = "qcom/x1e78100-lenovo-thinkpad-t14s-oled.dtb";
  };

  hardware.glasgow.enable = true;
  hardware.keyboard.qmk.enable = true;
  hardware.nitrokey.enable = true;
  hardware.sane.enable = true;

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
  ephemeral.device = "UUID=f20b114d-c519-4ded-b7db-a4641f948e9e";
  ephemeral.boot.device = "PARTUUID=d1dab2f8-46d6-46af-a265-f94347be8d4c";
  ephemeral.boot.fsType = "vfat";
  ephemeral.subvolumes."/home" = {
    options = [ "nodev" "nosuid" ];
    extraOptions = [ "lazytime" "compress=zstd:1" ];
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
    base = [ "nixos-test" "benchmark" "big-parallel" ];
    phys = base ++ [ "kvm" ];
    virt = base;

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
        supportedFeatures = phys ++ aarch;
        sshKey = "/etc/keys/nix-ssh";
      }
      {
        hostName = "nokotan.kyouma.net";
        protocol = "ssh";
        sshUser = "nix-ssh";
        maxJobs = 4;
        speedFactor = 8;
        systems = [ "aarch64-linux" ];
        supportedFeatures = phys ++ aarch;
        sshKey = "/etc/keys/nix-ssh";
      }
      {
        hostName = "schrodinger.kyouma.net";
        #protocol = "ssh-ng";
        sshUser = "root";
        maxJobs = 2;
        speedFactor = 4;
        systems = [ "riscv64-linux" ];
        supportedFeatures = phys ++ riscv;
        sshKey = "/etc/keys/nix-ssh";
      }
      {
        hostName = "ci-builder.nyantec.com";
        protocol = "ssh";
        sshUser = "nix-ssh";
        maxJobs = 8;
        speedFactor = 16;
        systems = [ "x86_64-linux" ];
        supportedFeatures = phys ++ x86-64;
        sshKey = "/etc/keys/nix-ssh";
      }
    ] ++ (lib.range 9 11 |> map (num: {
      hostName = "build-worker-${lib.fixedWidthNumber 2 num}";
      protocol = "ssh-ng";
      sshUser = "root";
      maxJobs = 2;
      speedFactor = 8;
      systems = [ "x86_64-linux" "i686-linux" "riscv64-linux" "aarch64-linux" ];
      supportedFeatures = virt ++ x86-64;
      sshKey = "/etc/keys/nix-ssh";
    }));

    settings.system-features = phys ++ x86-64 ++ riscv ++ aarch;
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
    dumpcap.enable = true;
    usbmon.enable = true;
  };

  services.beesd.filesystems.root = {
    spec = "UUID=67615b00-106f-42ba-aa3b-84874157b975";
    hashTableSizeMB = 2048;
    verbosity = "crit";
    extraOptions = [ "--throttle-factor" "1.0" ];
  };

  services.fprintd.enable = true;

  services.pcscd = {
    enable = true;
    plugins = with pkgs; [ pcsc-cyberjack ];
  };

  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    brlaser
  ];

  services.udev = {
    packages = with pkgs; [ utsushi ];
    extraRules = [
      [
        ''ACTION=="add|change"''
        ''SUBSYSTEM=="video4linux"''
        ''ATTRS{idVendor}=="0x046d"''
        ''ATTRS{idProduct}=="0x085e"''
        ''ATTR{index}=="0"''
        ''RUN+="${pkgs.v4l-utils}/bin/v4l2-ctl --device $devnode --set-ctrl pan_absolute=10800,tilt_absolute=-36000,zoom_absolute=150"''
      ]
      [
        ''ACTION=="add|change"''
        ''SUBSYSTEM=="usb"''
        ''ATTRS{idVendor}=="20a0"''
        ''ENV{PCSCLITE_IGNORE}="1"''
      ]
    ] |> map (lib.concatStringsSep ", ")
      |> lib.concatLines;
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
