{ self, ... }: { lib, pkgs, ... }: {
  boot.consoleLogLevel = lib.mkDefault 3;

  boot.initrd = {
    checkJournalingFS = lib.mkDefault false;
    includeDefaultModules = lib.mkDefault false;
    luks.cryptoModules = lib.mkDefault [ ];
    verbose = lib.mkDefault false;
  };

  boot.kernelPackages = lib.mkDefault
    (pkgs.linuxPackagesFor self.packages.${pkgs.system}.linux-hardened);
  boot.modprobeConfig.enable = lib.mkDefault false;

  boot.kernelParams = [
    # Disable kernel messages on the console
    "quiet"

    # Zero‐fill page and slab allocations on free
    "init_on_free=1"

    # Disable I/O delay
    "io_delay=none"

    # Enable page allocator free list randomisation
    "page_alloc.shuffle=1"

    # Disable slab merging
    "slab_nomerge"

    # Disable vsyscall mechanism
    "vsyscall=none"

    # Enable transparent hugepages
    "transparent_hugepage=always"

    # Suspend USB devices without delay
    "usbcore.autosuspend=0"
  ];

  boot.kernel.sysctl = {
    # Mitigate some TOCTOU vulnerabilities
    "fs.protected_fifos" = 2;
    "fs.protected_hardlinks" = 1;
    "fs.protected_regular" = 2;
    "fs.protected_symlinks" = 1;

    # Disable automatic loading of TTY line disciplines
    "dev.tty.ldisc_autoload" = 0;

    # Disable first 64 KiB of virtual memory for allocation
    "vm.mmap_min_addr" = 65536;

    # Increase ASLR randomisation
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;

    # Restrict ptrace()
    "kernel.yama.ptrace_scope" = 1;

    # Hide kernel memory addresses
    "kernel.kptr_restrict" = 2;

    # Restrict kernel log access
    "kernel.dmesg_restrict" = 1;

    # Enable hardened eBPF JIT
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_enable" = 1;
    "net.core.bpf_jit_harden" = 2;

    # Ignore ICMP redirects
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;

    # Set default Qdisc
    "net.core.default_qdisc" = "fq";

    # Increase minimum PMTU
    "net.ipv4.route.min_pmtu" = 1280;

    # Set default TCP congestion control algorithm
    "net.ipv4.tcp_congestion_control" = "bbr";

    # Enable ECN
    "net.ipv4.tcp_ecn" = 1;

    # Enable TCP fast open
    "net.ipv4.tcp_fastopen" = 3;

    # Disable TCP slow start after idling
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # Allow re‐use of TCP ports during TIME-WAIT
    "net.ipv4.tcp_tw_reuse" = 1;

    # Enable TCP MTU probing
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_mtu_probe_floor" = 1220;

    # Increase socket buffer space
    #  default of 16 MiB should be sufficient to saturate 1GE
    #  maximum for 54 MiB sufficient for 10GE
    "net.core.rmem_default" = 16777216;
    "net.core.rmem_max" = 56623104;
    "net.core.wmem_default" = 16777216;
    "net.core.wmem_max" = 56623104;
    "net.core.optmem_max" = 65536;
    "net.ipv4.tcp_rmem" = "4096 1048576 56623104";
    "net.ipv4.tcp_wmem" = "4096 65536 56623104";
    "net.ipv4.tcp_notsent_lowat" = 16384;
    "net.ipv4.udp_rmem_min" = 9216;
    "net.ipv4.udp_wmem_min" = 9216;

    # Reduce TCP keep‐alive time‐out to 2 minutes
    "net.ipv4.tcp_keepalive_time" = 60;
    "net.ipv4.tcp_keepalive_probes" = 6;
    "net.ipv4.tcp_keepalive_intvl" = 10;

    # Widen local port range
    "net.ipv4.ip_local_port_range" = "16384 65535";

    # Increase default MTU
    "net.ipv6.conf.default.mtu" = 1452;
    "net.ipv6.conf.all.mtu" = 1452;

    # Set traffic class for NDP to CS6 (network control)
    "net.ipv6.conf.default.ndisc_tclass" = 192;
    "net.ipv6.conf.all.ndisc_tclass" = 192;

    # Dirty page cache ratio
    "vm.dirty_background_ratio" = 3;
    "vm.dirty_ratio" = 6;
  };

  # Work around initrd generation bug
  environment.etc."modprobe.d/nixos.conf".text = "";

  systemd.tmpfiles.rules = [
    "w- /sys/kernel/mm/transparent_hugepage/enabled       - - - - always"
    "w- /sys/kernel/mm/transparent_hugepage/defrag        - - - - defer"
    "w- /sys/kernel/mm/transparent_hugepage/shmem_enabled - - - - within_size"
  ];
}
