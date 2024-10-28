{ self, ... }: { lib, config, pkgs, ... }: {
  imports = with self.nixosModules; [
    default
    mimalloc
    physical
  ];

  boot.kernelPackages = let
    inherit (self.packages.x86_64-linux) linux-hardened;
  in pkgs.linuxPackagesFor (linux-hardened.override {
    instSetArch = "znver2";
    extraConfig =
      (with linux-hardened.profile; physical // dm-crypt)
      // (with self.lib.kernel; {
        CPU_SUP_INTEL = false;
        CPU_SUP_AMD = true;
        NR_CPUS = 96;
        AMD_MEM_ENCRYPT = true;

        ACPI_IPMI = true;
        ACPI_HMAT = true;

        VIRTUALIZATION = true;
        KVM = true;
        KVM_AMD = true;
        KVM_SMM = true;

        NVME_CORE = true;
        BLK_DEV_NVME = true;
        NVME_VERBOSE_ERRORS = true;
        NVME_HWMON = true;

        ATA = true;
        ATA_VERBOSE_ERROR = true;
        ATA_ACPI = true;
        SATA_PMP = true;
        SATA_AHCI = true;
        SATA_MOBILE_LPM_POLICY = 1;
        ATA_SFF = false;

        BNXT = true;
        BNXT_FLOWER_OFFLOAD = true;
        BNXT_HWMON = true;
        MLX4_EN = true;
        MLX4_CORE_GEN2 = false;

        IPMI_HANDLER = true;
        IPMI_PANIC_EVENT = true;
        IPMI_PANIC_STRING = true;
        IPMI_DEVICE_INTERFACE = true;
        IPMI_SI = true;
        IPMI_SSIF = true;

        I2C_PIIX4 = true;

        HWMON = true;
        SENSORS_K10TEMP = true;

        WATCHDOG = true;
        WATCHDOG_HANDLE_BOOT_ENABLED = true;
        WATCHDOG_OPEN_TIMEOUT = 0;
        WATCHDOG_SYSFS = true;
        SP5100_TCO = true;

        VIDEO = true;
        DRM = true;
        DRM_FBDEV_EMULATION = true;
        DRM_AST = true;

        EDAC_DECODE_MCE = true;
        EDAC_AMD64 = true;

        AMD_PTDMA = true;
        AMD_IOMMU = true;

        INTEL_RAPL = true;

        BTRFS_FS = true;
        BTRFS_FS_POSIX_ACL = true;

        CEPH_FS = true;
        CEPH_FS_POSIX_ACL = true;

        CRYPTO_DEV_CCP = true;
        CRYPTO_DEV_CCP_DD = true;
        CRYPTO_DEV_SP_CCP = true;
        CRYPTO_DEV_CCP_CRYPTO = true;
        CRYPTO_DEV_SP_PSP = true;
      });
  });

  ephemeral = {
    device = "nodev";
    boot = {
      device = "nodev";
      fsType = "vfat";
    };
  };
}
