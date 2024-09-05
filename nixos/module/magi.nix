{ self, ... }: { lib, config, pkgs, ... }: {
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
        IPMI_WATCHDOG = true;

        HWMON = true;
        SENSORS_K10TEMP = true;
        SENSORS_ACPI_POWER = true;

        AMD_IOMMU = true;

        BTRFS_FS = true;
        BTRFS_FS_POSIX_ACL = true;

        CEPH_FS = true;
        CEPH_FS_POSIX_ACL = true;
      });
  });
}
