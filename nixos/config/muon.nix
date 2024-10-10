{ self, nixos-hardware, ... }: { lib, config, pkgs, ... }: {
imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme-gen4
  ] ++ (with self.nixosModules; [
    default
    mimalloc
    physical
    portable
    graphical
    wireless
  ]);

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" "riscv64-linux" ];
    preferStaticEmulators = true;
  };

  boot.initrd = {
    luks.devices."luks-2fb93d4f-a0fe-4a49-9e40-3ac38ffe4d75".device = "/dev/disk/by-uuid/2fb93d4f-a0fe-4a49-9e40-3ac38ffe4d75";
    luks.devices."luks-ea77e674-847f-41b8-9e1d-8b6dd08710e6".device = "/dev/disk/by-uuid/ea77e674-847f-41b8-9e1d-8b6dd08710e6";
  };

  boot.kernelParams = [
    "intel_iommu=on"
    "nouveau.config=NvGspRm=1"
  ];

  boot.kernelPackages = let
    inherit (self.packages.x86_64-linux) linux-hardened;
  in pkgs.linuxPackagesFor (linux-hardened.override {
    instSetArch = "alderlake";
    extraFirmware = [
      "i915/adlp_dmc.bin"
      "i915/adlp_dmc_ver2_16.bin"
      "i915/adlp_guc_70.bin"
      "i915/tgl_huc.bin"
      "intel/ibt-0040-0041.sfi"
      "intel/ibt-0040-0041.ddc"
      "intel/sof/sof-adl.ri"
      "intel/sof-tplg/sof-hda-generic-2ch.tplg"
      "iwlwifi-so-a0-gf-a0-89.ucode"
      "iwlwifi-so-a0-gf-a0.pnvm"
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
      "regulatory.db"
      "regulatory.db.p7s"
      "rtl_nic/rtl8153b-2.fw"
    ];

    extraConfig =
      (with linux-hardened.profile; physical // portable // dm-crypt // wireless // audio)
      // (with self.lib.kernel; {
        X86_INTEL_LPSS = true;

        CPU_SUP_INTEL = true;
        CPU_SUP_AMD = false;
        NR_CPUS = 20;
        X86_MCE_INTEL = true;

        ACPI_DPTF = true;
        DPTF_POWER = true;
        DPTF_PCH_FIVR = true;
        INTEL_IDLE = true;

        VIRTUALIZATION = true;
        KVM = true;
        KVM_INTEL = true;
        KVM_SMM = true;

        IP_MULTICAST = true;

        IPV6_ROUTER_PREF = true;
        IPV6_ROUTE_INFO = true;
        IPV6_OPTIMISTIC_DAD = true;

        BT_INTEL = true;
        BT_HCIBTUSB = true;

        EISA = true;
        EISA_PCI_EISA = true;
        EISA_VIRTUAL_ROOT = false;
        EISA_NAMES = true;

        NVME_CORE = true;
        BLK_DEV_NVME = true;
        NVME_VERBOSE_ERRORS = true;
        NVME_HWMON = true;

        MISC_RTSX = true;
        INTEL_MEI = true;
        MISC_RTSX_PCI = true;

        ETHERNET = true;
        AQTION = true;

        WLAN = true;
        IWLWIFI = true;
        IWLMVM = true;

        INPUT_MOUSEDEV = true;
        INPUT_JOYDEV = true;

        KEYBOARD_ATKBD = true;

        INPUT_MOUSE = true;
        MOUSE_PS2 = true;
        MOUSE_PS2_TRACKPOINT = true;

        INPUT_JOYSTICK = true;

        INTEL_PCH_THERMAL = true;

        MFD_CORE = true;
        MFD_INTEL_LPSS_PCI = true;

        I2C = true;
        I2C_I801 = true;

        SPI = true;
        SPI_MEM = true;
        SPI_INTEL_PCI = true;

        INT340X_THERMAL = true;

        VIDEO = true;
        VGA_SWITCHEROO = true;
        DRM = true;
        DRM_FBDEV_EMULATION = true;
        DRM_NOUVEAU = true;
        DRM_NOUVEAU_SVM = true;
        DRM_NOUVEAU_GSP_DEFAULT = true;
        DRM_I915 = true;

        BACKLIGHT_CLASS_DEVICE = true;

        HDMI = true;

        SND_HDA_INTEL = true;
        SND_HDA_HWDEP = true;
        SND_HDA_CODEC_REALTEK = true;
        SND_HDA_CODEC_HDMI = true;
        SND_HDA_POWER_SAVE_DEFAULT = 2;

        SND_SOC = true;
        SND_SOC_SOF_TOPLEVEL = true;
        SND_SOC_SOF_PCI = true;
        SND_SOC_SOF_INTEL_TOPLEVEL = true;
        SND_SOC_SOF_TIGERLAKE = true;
        SND_SOC_SOF_HDA_LINK = true;
        SND_SOC_SOF_HDA_AUDIO_CODEC = true;
        SND_SOC_DMIC = true;

        HID_LENOVO = true;
        HID_LOGITECH = true;

        USB_ACM = true;

        USB_SERIAL = true;
        USB_SERIAL_PL2303 = true;

        EDAC_IGEN6 = true;

        ACPI_WMI = true;
        MXM_WMI = true;
        THINKPAD_ACPI = true;
        THINKPAD_ACPI_ALSA_SUPPORT = true;
        THINKPAD_ACPI_VIDEO = true;

        INTEL_TURBO_MAX_3 = true;
        INTEL_VSEC = true;

        INTEL_IOMMU = true;
        INTEL_IOMMU_DEFAULT_ON = true;

        SOUNDWIRE = true;
        SOUNDWIRE_INTEL = true;

        INTEL_IDMA64 = true;

        INTEL_RAPL = true;

        BTRFS_FS = true;
        BTRFS_FS_POSIX_ACL = true;
        FUSE_FS = true;
        EXFAT_FS = true;
      });
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

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "localhost";
        protocol = null;
        maxJobs = 2;
        speedFactor = 12;
        systems = [ "x86_64-linux" "aarch64-linux" "riscv64-linux" ];
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" "gccarch-x86-64" "gccarch-x86-64-v2" "gccarch-x86-64-v3" ];
      }
      {
        hostName = "integra.kyouma.net";
        protocol = "ssh-ng";
        sshUser = "nix-ssh";
        maxJobs = 2;
        speedFactor = 4;
        systems = [ "aarch64-linux" ];
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        sshKey = "/etc/keys/nix-ssh";
      }
    ] ++ lib.forEach [ "01" "02" "03" "04" "05" "06" "07" "08" ] (num: {
      hostName = "build-worker-${num}";
      protocol = "ssh-ng";
      sshUser = "root";
      maxJobs = 4;
      speedFactor = 16;
      systems = [ "x86_64-linux" "i686-linux" ];
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" "gccarch-x86-64" "gccarch-x86-64-v2" "gccarch-x86-64-v3" ];
      sshKey = "/etc/keys/nix-ssh";
    });
  };

  programs.ssh = {
    knownHosts = {
      "[build-worker-kyoumanet.fly.dev]:2201".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDL2M97UBHg9aUfjDUxzmzg1r0ga0m3/stummBVwuEAB";
      "[build-worker-kyoumanet.fly.dev]:2202".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOTwVKL0P0chPM2Gz23rbT94844+w1CGJdCaZdzfjThz";
      "[build-worker-kyoumanet.fly.dev]:2203".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAjy2eZGJQeAYy0+fLgW9jiS0jVY2LInY0NDMnzCvvKp";
      "[build-worker-kyoumanet.fly.dev]:2204".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN72OyD9LYy4hq0WZ7ie5RPV+G54UreEJiA/RubjGoe9";
      "[build-worker-kyoumanet.fly.dev]:2205".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICNh1o1I98XrI2XmOI6Q0aHPfyLCIQwKkKOxGUUeXL9v";
      "[build-worker-kyoumanet.fly.dev]:2206".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGf0kxGgwOG9KhUhvxxTSiQC5YikrzZXKDgSpBw33qN4";
      "[build-worker-kyoumanet.fly.dev]:2207".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL9z95a6Fn/dB+iNigEYpuJdBnBwCkIZYaKHcFbGP+RY";
      "[build-worker-kyoumanet.fly.dev]:2208".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAk+FNMhTfAVqk3MfLp4QiG/i5ti53DlpnC0q+sOvU9O";
      "integra.kyouma.net".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBwEQiSfaDrUAwgul4mktusBPcIVxI4pLNDh9DPopVU";
      "zh1830.rsync.net".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJtclizeBy1Uo3D86HpgD3LONGVH0CJ0NT+YfZlldAJd";
    };

    extraConfig = ''
      Host build-worker-01
        Hostname build-worker-kyoumanet.fly.dev
        Port 2201
      Host build-worker-02
        Hostname build-worker-kyoumanet.fly.dev
        Port 2202
      Host build-worker-03
        Hostname build-worker-kyoumanet.fly.dev
        Port 2203
      Host build-worker-04
        Hostname build-worker-kyoumanet.fly.dev
        Port 2204
      Host build-worker-05
        Hostname build-worker-kyoumanet.fly.dev
        Port 2205
      Host build-worker-06
        Hostname build-worker-kyoumanet.fly.dev
        Port 2206
      Host build-worker-07
        Hostname build-worker-kyoumanet.fly.dev
        Port 2207
      Host build-worker-08
        Hostname build-worker-kyoumanet.fly.dev
        Port 2208
    '';
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

  services.udev.packages = with pkgs; [ utsushi ];

  systemd.services."beesd@root" = {
    bindsTo = [ "power-external.target" ];
    serviceConfig = {
      IOSchedulingClass = "idle";
      CPUWeight = lib.mkForce "idle";
    };
  };

  users.users.nil.hashedPasswordFile = "/etc/keys/users/nil";
  users.users.nil.extraGroups = [
    "audio" "input" "uinput" "plugdev" "video" "render" "scanner" "nitrokey"
  ];
}
