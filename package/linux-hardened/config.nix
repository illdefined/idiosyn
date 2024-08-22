{ kernel, lib, hostPlatform, systemd }: with kernel; {
  meta = {
    EXPERT = true;
    STAGING = true;
  } // lib.optionalAttrs hostPlatform.isx86_64 {
    PROCESSOR_SELECT = true;
  };

  build = {
    COMPILE_TEST = false;
    WERROR = true;

    STANDALONE = true;
    PREVENT_FIRMWARE_BUILD = true;

    JUMP_LABEL = true;

    LTO_CLANG_FULL = true;
  };

  boot = {
    KERNEL_ZSTD = true;
    BLK_DEV_INITRD = true;
    RD_GZIP = false;
    RD_BZIP2 = false;
    RD_LZMA = false;
    RD_XZ = false;
    RD_LZO = false;
    RD_LZ4 = false;
    RD_ZSTD = true;

    BOOT_CONFIG = true;

    EFI = true;
    EFI_STUB = true;

    DEVTMPFS = true;
    DEVTMPFS_MOUNT = true;
    DEVTMPFS_SAFE = true;

    FW_LOADER = true;
    FW_LOADER_COMPRESS = true;
    FW_LOADER_COMPRESS_XZ = false;
    FW_LOADER_COMPRESS_ZSTD = true;
    FW_CACHE = true;
  } // lib.optionalAttrs hostPlatform.isx86_64 {
    EFI_HANDOVER_PROTOCOL = false;
  };

  debug = {
    KALLSYMS = true;
    KALLSYMS_ALL = false;

    SYMBOLIC_ERRNAME = true;
    DEBUG_BUGVERBOSE = true;
    DEBUG_INFO_DWARF5 = true;
    DEBUG_INFO_SPLIT = true;
    STRIP_ASM_SYMS = true;

    MAGIC_SYSRQ = true;
    MAGIC_SYSRQ_DEFAULT_ENABLE = "0x1f4";

    SLUB_DEBUG = false;

    DEBUG_WX = true;
    WARN_ALL_UNSEEDED_RANDOM = true;

    RCU_TRACE = false;

  } // lib.optionalAttrs hostPlatform.isx86_64 {
    X86_VERBOSE_BOOTUP = false;
    EARLY_PRINTK = false;
    X86_DEBUG_FPU = false;

    UNWINDER_ORC = true;
  };

  firmware = {
    EFI_BOOTLOADER_CONTROL = true;
    RESET_ATTACK_MITIGATION = true;
    EFI_DISABLE_PCI_DMA = true;

    EFIVAR_FS = true;

    # pstore
    PSTORE = true;
    PSTORE_COMPRESS = true;
    EFI_VARS_PSTORE = true;
  };

  platform = {
    "64BIT" = true;
  } // lib.optionalAttrs hostPlatform.isx86_64 {
    X86_MPPARSE = false;
    X86_FRED = true;
    X86_EXTENDED_PLATFORM = false;

    CPU_SUP_HYGON = false;
    CPU_SUP_CENTAUR = false;
    CPU_SUP_ZHAOXIN = false;
  } // lib.optionalAttrs hostPlatform.isAarch64 {
    ARM64_VA_BITS_48 = true;
    ARM64_PAN = true;
    ARM64_USE_LSE_ATOMICS = true;
    ARM64_CNP = true;
    ARM64_PTR_AUTH = true;
    ARM64_EPAN = true;
  } // lib.optionalAttrs hostPlatform.isRiscV64 {
    ARCH_RV64I = true;
    COMPAT = false;
  };

  security = {
    SECCOMP = true;

    # Kernel memory base
    RELOCATABLE = true;
    RANDOMIZE_BASE = true;
    RANDOMIZE_MEMORY = true;

    # Stack protection
    STACKPROTECTOR = true;
    STACKPROTECTOR_STRONG = true;
    VMAP_STACK = true;
    RANDOMIZE_KSTACK_OFFSET = true;
    RANDOMIZE_KSTACK_OFFSET_DEFAULT = true;
    INIT_STACK_ALL_ZERO = true;

    STRICT_KERNEL_RWX = true;
    CFI_CLANG = true;

    # Slab allocator
    SLAB_MERGE_DEFAULT = false;
    SLAB_FREELIST_RANDOM = true;
    SLAB_FREELIST_HARDENED = true;
    SLAB_CANARY = true;
    SLUB_CPU_PARTIAL = true;
    RANDOM_KMALLOC_CACHES = true;

    # Page allocator
    SHUFFLE_PAGE_ALLOCATOR = true;
    COMPAT_BRK = false;
    INIT_ON_FREE_DEFAULT_ON = true;

    # False positives in combination with panic on BUG()
    PAGE_SANITIZE_VERIFY = false;
    SLAB_SANITIZE_VERIFY = false;

    MODULES = false;

    LDISC_AUTOLOAD = false;

    DEVMEM = false;
    DEVPORT = false;

    DEBUG_FS = false;

    # Bounds checking
    # False positives in iwlwifi
    #UBSAN = true;
    #UBSAN_BOUNDS = true;
    #UBSAN_SIGNED_WRAP = false;
    #UBSAN_BOOL = false;
    #UBSAN_ENUM = false;

    # Memory safety error detection
    KFENCE = true;
    KFENCE_DEFERRABLE = true;
    KFENCE_BUG_ON_DATA_CORRUPTION = true;

    PANIC_ON_OOPS = true;
    PANIC_TIMEOUT = (-1);

    HARDENED_USERCOPY = true;
    FORTIFY_SOURCE = true;

    SECURITY_DMESG_RESTRICT = true;
    SECURITY_PERF_EVENTS_RESTRICT = true;
    SECURITY_TIOCSTI_RESTRICT = true;
    SECURITY = true;
    SECURITY_NETWORK = true;
    SECURITY_SELINUX = false;
    SECURITY_YAMA = true;
    SECURITY_LOCKDOWN_LSM = true;
    SECURITY_LOCKDOWN_LSM_EARLY = true;
    LOCK_DOWN_KERNEL_FORCE_CONFIDENTIALITY = true;
    SECURITY_LANDLOCK = true;

    LIST_HARDENED = true;
    BUG_ON_DATA_CORRUPTION = true;

  } // lib.optionalAttrs hostPlatform.isx86_64 {
    X86_UMIP = true;
    X86_USER_SHADOW_STACK = true;

    STRICT_SIGALTSTACK_SIZE = true;
  };

  timer = {
    NO_HZ_FULL = true;
    HIGH_RES_TIMERS = true;
    HZ_1000 = true;

    RTC_CLASS = true;
    RTC_HCTOSYS = true;
    RTC_SYSTOHC = true;
  } // lib.optionalAttrs hostPlatform.isx86_64 {
    X86_PM_TIMER = true;
    RTC_DRV_CMOS = true;
  };

  interfaces = {
    SYSVIPC = true;
    USELIB = false;

    UID16 = false;
    SGETMASK_SYSCALL = false;
    SYSFS_SYSCALL = false;
    POSIX_TIMERS = true;
    PCSPKR_PLATFORM = false;
    FUTEX = true;
    EPOLL = true;
    AIO = false;
    IO_URING = true;
    ADVISE_SYSCALLS = true;

    COMPAT_VDSO = false;
    COMPAT_32BIT_TIME = false;

    # Required for BPF LSM instrumentation
    PERF_EVENTS = true;

    DNOTIFY = false;

    bpf = {
      BPF_SYSCALL = true;
      BPF_JIT = true;
      BPF_JIT_ALWAYS_ON = true;
      BPF_UNPRIV_DEFAULT_OFF = true;
      BPF_LSM = true;
    };

    namespaces = {
      NAMESPACES = true;
      UTS_NS = true;
      TIME_NS = true;
      USER_NS = true;
      USER_NS_UNPRIVILEGED = false;
      PID_NS = true;
      NET_NS = true;
    };
  } // lib.optionalAttrs hostPlatform.isx86_64 {
    X86_VSYSCALL_EMULATION = false;
    X86_IOPL_IOPERM = false;
    LEGACY_VSYSCALL_NONE = true;
    MODIFY_LDT_SYSCALL = false;
    IA32_EMULATION = false;
  };

  scheduler = {
    SMP = true;
    PREEMPT_DYNAMIC = false;

    SCHED_CORE = true;
    SCHED_CLUSTER = true;
    SCHED_MC = true;
    SCHED_AUTOGROUP = true;

    RCU_NOCB_CPU_DEFAULT_ALL = true;
    RCU_LAZY = true;

    CGROUPS = true;
    BLK_CGROUP = true;
    CGROUP_SCHED = true;

  } // lib.optionalAttrs hostPlatform.isx86_64 {
    SCHED_OMIT_FRAME_POINTER = true;

    SCHED_MC_PRIO = true;
  };

  memory = {
    NUMA = true;
    NUMA_BALANCING = true;
    NUMA_BALANCING_DEFAULT_ENABLED = true;

    SPARSEMEM_VMEMMAP = true;
    MEMORY_HOTPLUG = true;
    MEMORY_HOTREMOVE = true;

    COMPACTION = true;
    MIGRATION = true;

    KSM = true;

    TRANSPARENT_HUGEPAGE = true;
    TRANSPARENT_HUGEPAGE_ALWAYS = true;
    READ_ONLY_THP_FOR_FS = true;
    HUGETLBFS = true;
    HUGETLB_PAGE_OPTIMIZE_VMEMMAP = option true;
    HUGETLB_PAGE_OPTIMIZE_VMEMMAP_DEFAULT_ON = option true;

    DEFERRED_STRUCT_PAGE_INIT = true;

    ZONE_DEVICE = true;
    DEVICE_PRIVATE = true;

    LRU_GEN = true;
    LRU_GEN_ENABLED = true;

    DMADEVICES = true;
    ASYNC_TX_DMA = option true;

    zram = {
      SWAP = true;
      ZSMALLOC = true;
      ZRAM = true;
      ZRAM_DEF_COMP_ZSTD = true;
      ZRAM_WRITEBACK = true;
      CRYPTO_ZSTD = true;
    };
  } // lib.optionalAttrs hostPlatform.isx86_64 {
    AMD_NUMA = option false;
    X86_64_ACPI_NUMA = true;

    X86_INTEL_TSX_MODE_AUTO = true;

    ADDRESS_MASKING = false;
  };

  block = {
    BLOCK = true;
    BLOCK_LEGACY_AUTOLOAD = false;
    BLK_DEV = true;
    BLK_DEV_WRITE_MOUNTED = true;
    BLK_WBT = true;
    BLK_WBT_MQ = true;

    PARTITION_ADVANCED = true;
    MSDOS_PARTITION = false;
    EFI_PARTITION = true;

    MQ_IOSCHED_DEADLINE = true;
    MQ_IOSCHED_KYBER = true;
    IOSCHED_BFQ = true;
    BFQ_GROUP_IOSCHED = true;

    BLK_DEV_LOOP = true;
    BLK_DEV_LOOP_MIN_COUNT = 0;
  };

  binfmt = {
    BINFMT_ELF = true;
    CORE_DUMP_DEFAULT_ELF_HEADERS = true;
    BINFMT_SCRIPT = true;
    BINFMT_MISC = true;
    COREDUMP = true;
  };

  io = {
    IOMMU_SUPPORT = true;
    IOMMU_DEFAULT_DMA_STRICT = true;
    IRQ_REMAP = true;
    SWIOTLB_DYNAMIC = true;
  } // lib.optionalAttrs hostPlatform.isx86_64 {
    X86_X2APIC = true;

    AMD_IOMMU = option true;
    INTEL_IOMMU = option true;
    INTEL_IOMMU_SVM = option true;
    INTEL_IOMMU_DEFAULT_ON = option true;
    INTEL_IOMMU_SCALABLE_MODE_DEFAULT_ON = option true;

    IO_DELAY_NONE = true;
  } // lib.optionalAttrs hostPlatform.isAarch64 {
    ARM_SMMU_V3 = true;
  };

  bus = {
    PCI = true;
    PCIEPORTBUS = true;
    PCI_MSI = true;
    PCIE_BUS_PERFORMANCE = true;

    HID_SUPPORT = true;
    HID = true;
    HIDRAW = true;
    UHID = true;
    HID_GENERIC = true;
    USB_HID = true;
    USB_HIDDEV = true;

    USB_SUPPORT = true;
    USB = true;
    USB_PCI = true;
    USB_ANNOUNCE_NEW_DEVICES = true;
    USB_DEFAULT_PERSIST = true;
    USB_DYNAMIC_MINORS = true;
    USB_XHCI_HCD = true;
    USB_XHCI_PCI = true;
  };

  power = {
    PM = true;
    ENERGY_MODEL = true;
    ACPI = true;
    ACPI_APEI = true;
    ACPI_NUMA = true;

    CPU_FREQ = true;
    CPU_FREQ_STAT = true;
    CPU_FREQ_DEFAULT_GOV_SCHEDUTIL = true;
    CPU_FREQ_GOV_SCHEDUTIL = true;

    CPU_IDLE = true;
    CPU_IDLE_GOV_MENU = false;
    CPU_IDLE_GOV_TEO = true;

    PCIEASPM = true;
    PCIEASPM_POWER_SUPERSAVE = true;

  } // lib.optionalAttrs hostPlatform.isx86_64 {
    X86_ACPI_CPUFREQ = true;
    X86_ACPI_CPUFREQ_CPB = false;
  } // lib.optionalAttrs (hostPlatform.isAarch64 || hostPlatform.isRiscV64) {
    ACPI_CPPC_CPUFREQ = true;
  };

  framebuffer = {
    DRM_SIMPLE_DRM = option true;
    FB = true;
    FB_EFI = true;
    FB_SIMPLE = option true;
    FB_DEVICE = false;
    VGA_CONSOLE = false;
    FRAMEBUFFER_CONSOLE = true;
    FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER = true;
    SYSFB_SIMPLEFB = true;
  };

  network = {
    NET = true;
    PACKET = true;
    PACKET_DIAG = true;
    UNIX = true;
    UNIX_DIAG = true;
    XDP_SOCKETS = true;
    XDP_SOCKETS_DIAG = true;
    INET = true;
    SYN_COOKIES = true;
    INET_DIAG = true;
    INET_UDP_DIAG = true;
    INET_RAW_DIAG = true;

    TCP_CONG_ADVANCED = true;
    TCP_CONG_BIC = false;
    TCP_CONG_CUBIC = false;
    TCP_CONG_WESTWOOD = false;
    TCP_CONG_HTCP = false;
    TCP_CONG_BBR = true;
    DEFAULT_BBR = true;

    IPV6 = true;

    NETFILTER = true;
    NETFILTER_ADVANCED = true;
    NETFILTER_INGRESS = true;
    NETFILTER_EGRESS = true;

    NETFILTER_NETLINK_LOG = true;
    NF_LOG_SYSLOG = true;

    NF_CONNTRACK = true;
    NF_TABLES = true;
    NF_TABLES_INET = true;
    NFT_CT = true;
    NFT_CONNLIMIT = true;
    NFT_LIMIT = true;
    NFT_LOG = true;
    NFT_REJECT = true;
    NFT_FIB_INET = true;
    NF_TABLES_IPV4 = true;
    NFT_FIB_IPV4 = true;
    NF_TABLES_IPV6 = true;
    NFT_FIB_IPV6 = true;

    NET_SCH_CAKE = true;
    NET_SCH_FQ = true;
    NET_SCH_DEFAULT = true;
    DEFAULT_FQ = true;
    DEFAULT_NET_SCH = "fq";

    NETLINK_DIAG = true;
    ETHTOOL_NETLINK = true;

    NETDEVICES = true;
    ETHERNET = true;
  };

  chardev = {
    TTY = true;
    VT = true;
    CONSOLE_TRANSLATIONS = true;
    VT_CONSOLE = true;
    UNIX98_PTYS = true;

    SERIAL_DEV_BUS = true;
    SERIAL_DEV_CTRL_TTYPORT = true;

    HW_RANDOM = true;
    HW_RANDOM_INTEL = false;
    HW_RANDOM_AMD = false;
    HW_RANDOM_VIA = false;

    TCG_TPM = true;
    TCG_TPM2_HMAC = true;
    HW_RANDOM_TPM = true;
    TCG_TIS = true;
    TCG_CRB = true;
  };

  input = {
    INPUT = true;
    INPUT_SPARSEKMAP = true;
    INPUT_EVDEV = true;
    INPUT_KEYBOARD = true;
  };

  filesystem = {
    OVERLAY_FS = true;
    OVERLAY_FS_REDIRECT_DIR = true;
    OVERLAY_FS_REDIRECT_ALWAYS_FOLLOW = false;
    OVERLAY_FS_XINO_AUTO = true;
    OVERLAY_FS_METACOPY = true;

    MSDOS_FS = true;
    VFAT_FS = true;
    FAT_DEFAULT_UTF8 = true;

    PROC_FS = true;
    PROC_KCORE = false;
    PROC_SYSCTL = true;
    PROC_PAGE_MONITOR = true;
    SYSFS = true;
    TMPFS = true;
    TMPFS_POSIX_ACL = true;
    EFIVAR_FS = true;

    EROFS_FS = true;
    EROFS_FS_XATTR = true;
    EROFS_FS_POSIX_ACL = true;
    EROFS_FS_SECURITY = false;
    EROFS_FS_ZIP = true;
    EROFS_FS_ZIP_ZSTD = true;

    NLS = true;
    NLS_CODEPAGE_437 = true;
    NLS_ISO8859_1 = true;
    UNICODE = true;
  };

  fonts = {
    FONTS = true;
    FONT_TER16x32 = true;
  };

  systemd = lib.optionalAttrs (lib.meta.availableOn hostPlatform systemd) {
    # Base requirements
    DEVTMPFS = true;
    CGROUPS = true;
    INOTIFY_USER = true;
    SIGNALFD = true;
    TIMERFD = true;
    EPOLL = true;
    UNIX = true;
    PROC_FS = true;
    FHANDLE = true;

    # Legacy interfaces
    UEVENT_HELPER = false;
    FW_LOADER_USER_HELPER = false;

    # udev & virtualisation
    DMIID = true;

    # SCSI device serial number retrieval
    BLK_DEV_BSG = option true;

    # PrivateNetwork
    NET_NS = true;

    # PrivateUser
    USER_NS = true;

    # Optional but recommended
    IPV6 = true;
    AUTOFS_FS = true;
    TMPFS_XATTR = true;
    TMPFS_POSIX_ACL = true;
    SECCOMP = true;
    SECCOMP_FILTER = true;
    KCMP = true;
    NET_SCHED = true;

    # CPUShares
    CGROUP_SCHED = true;
    FAIR_GROUP_SCHED = true;

    # CPUQuota
    CFS_BANDWIDTH = true;

    # IPaddress{Allow,Deny}, SocketBind{Allow,Deny}, RestrictNetworkInterfaces
    BPF = true;
    BPF_SYSCALL = true;
    BPF_JIT = true;
    CGROUP_BPF = true;

    # EFI
    EFIVAR_FS = true;
    EFI_PARTITION = true;

    # SMBIOS credentials
    DMI = true;
    DMI_SYSFS = true;

    # Real‐time scheduling
    RT_GROUP_SCHED = false;

    # systemd-oomd
    PSI = true;
    MEMCG = true;

    AUDIT = false;
  };
}
