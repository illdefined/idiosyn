{ kernel, lib, hostPlatform }: with kernel; {
  paravirt = {
    HYPERVISOR_GUEST = true;
    PARAVIRT = true;
    PARAVIRT_SPINLOCKS = true;
    KVM_GUEST = true;
    ARCH_CPUIDLE_HALTPOLL = true;
    PARAVIRT_CLOCK = true;

    HALTPOLL_CPUIDLE = true;

    FW_CFG_SYSFS = true;

    BLK_MQ_VIRTIO = true;
    VIRTIO_BLK = true;
    VIRTIO_NET = true;
    VIRTIO_CONSOLE = true;

    HW_RANDOM_VIRTIO = true;

    DRM = true;
    DRM_FBDEV_EMULATION = true;
    DRM_VIRTIO_GPU = true;
    DRM_VIRTIO_GPU_KMS = true;
    DRM_BOCHS = true;
    DRM_SIMPLEDRM = true;

    VIRT_DRIVERS = true;
    VMGENID = true;

    VIRTIO_MENU = true;
    VIRTIO = true;
    VIRTIO_PCI = true;
    VIRTIO_PCI_LEGACY = false;
    VIRTIO_BALLOON = true;
    VIRTIO_INPUT = true;

    VIRTIO_IOMMU = true;

    FUSE_FS = true;
    VIRTIO_FS = true;
  };

  physical = {
    ACPI_BUTTON = true;
    ACPI_VIDEO = true;
    ACPI_FAN = true;
    ACPI_TAD = true;
    ACPI_PROCESSOR_AGGREGATOR = true;
    ACPI_THERMAL = true;
    ACPI_PCI_SLOT = true;

    SCSI = true;
    BLK_DEV_SD = true;
    CHR_DEV_SG = true;
    SCSI_CONSTANTS = true;
    SCSI_SCAN_ASYNC = true;

    USB_STORAGE = true;
    USB_UAS = true;

    LEDS_CLASS = true;
    LEDS_TRIGGERS = true;
    LEDS_TRIGGER_PANIC = true;
    LEDS_TRIGGER_NETDEV = true;

    EDAC = true;

    THERMAL = true;
    THERMAL_NETLINK = true;
    THERMAL_DEFAULT_GOV_FAIR_SHARE = true;
    THERMAL_GOV_FAIR_SHARE = true;

    POWERCAP = true;

    RAS = true;
  };

  portable = {
    PREEMPT_VOLUNTARY = true;

    SUSPEND = true;
    WQ_POWER_EFFICIENT_DEFAULT = true;
    ACPI_BATTERY = true;

    HOTPLUG_PCI_PCIE = true;
    HOTPLUG_PCI = true;

    MEDIA_SUPPORT = true;
    MEDIA_SUPPORT_FILTER = true;
    MEDIA_SUBDRV_AUTOSELECT = true;
    MEDIA_CAMERA_SUPPORT = true;
    MEDIA_USB_SUPPORT = true;
    USB_VIDEO_CLASS = true;
    USB_VIDEO_CLASS_INPUT_EVDEV = true;

    HID_BATTERY_STRENGTH = true;

    USB_NET_DRIVERS = true;
    USB_RTL8152 = true;
    USB_USBNET = true;
    USB_NET_AX88179_178A = true;
    USB_NET_CDCETHER = true;
    USB_NET_CDC_SUBSET = true;

    BACKLIGHT_CLASS_DEVICE = true;

    TYPEC = true;
    TYPEC_TCPM = true;
    TYPEC_TCPCI = true;
    TYPEC_UCSI = true;
    UCSI_ACPI = true;
    TYPEC_DP_ALTMODE = true;

    MMC = true;
    MMC_BLOCK = true;

    USB4 = true;

    KFENCE_SAMPLE_INTERVAL = "500";
  };

  dm-crypt = {
    MD = true;
    MD_BITMAP_FILE = false;
    BLK_DEV_DM = true;
    DM_CRYPT = true;
    DM_UEVENT = true;
    DM_INTEGRITY = true;

    CRYPTO_AES = true;
    CRYPTO_XTS = true;
    CRYPTO_AEGIS128 = true;
    CRYPTO_SHA256 = true;

    CRYPTO_USER_API_HASH = true;
    CRYPTO_USER_API_SKCIPHER = true;
  } // lib.optionalAttrs hostPlatform.isx86_64 {
    CRYPTO_AES_NI_INTEL = true;
    CRYPTO_AEGIS128_AESNI_SSE2 = true;
    CRYPTO_SHA256_SSSE3 = true;
  } // lib.optionalAttrs hostPlatform.isRiscV64 {
    CRYPTO_AES_RISCV64 = true;
    CRYPTO_SHA256_RISCV64 = true;
  } // lib.optionalAttrs hostPlatform.isAarch64 {
    CRYPTO_AES_ARM64 = true;
    CRYPTO_AES_ARM64_CE = true;
    CRYPTO_AES_ARM64_CE_BLK = true;
    CRYPTO_AES_ARM64_NEON_BLK = true;
    CRYPTO_AES_ARM64_BS = true;
    CRYPTO_AEGIS128_SIMD = true;
    CRYPTO_SHA256_ARM64 = true;
  };

  wireless = {
    WIRELESS = true;
    CFG80211 = true;
    CFG80211_DEFAULT_PS = true;
    CFG80211_CRDA_SUPPORT = true;
    MAC80211 = true;
    MAC80211_RC_MINSTREL = true;
    MAC80211_RC_DEFAULT_MINSTREL = true;
    MAC80211_LEDS = true;

    BT = true;
    BT_BREDR = true;
    BT_RFCOMM = true;
    BT_HIDP = true;
    BT_LE = true;
    BT_LEDS = true;

    BT_HCIBTUSB_AUTOSUSPEND = option true;
    BT_HCIBTUSB_BCM = option false;
    BT_HCIBTUSB_RTL = option false;

    RFKILL = true;
    RFKILL_INPUT = true;

    # iwd
    KEYS = true;
    CRYPTO_USER_API_SKCIPHER = true;
    CRYPTO_USER_API_HASH = true;
    CRYPTO_HMAC = true;
    CRYPTO_CMAC = true;
    CRYPTO_MD4 = true;
    CRYPTO_MD5 = true;
    CRYPTO_SHA1 = true;
    CRYPTO_SHA256 = true;
    CRYPTO_SHA512 = true;
    CRYPTO_AES = true;
    CRYPTO_ECB = true;
    CRYPTO_DES = true;
    CRYPTO_CBC = true;

    ASYMMETRIC_KEY_TYPE = option true;
    ASYMMETRIC_PUBLIC_KEY_SUBTYPE = option true;
    X509_CERTIFICATE_PARSER = option true;
    PKCS7_MESSAGE_PARSER = option true;
    PKCS8_PRIVATE_KEY_PARSER = option true;
  } // lib.optionalAttrs hostPlatform.isx86_64 {
    CRYPTO_AES_NI_INTEL = option true;
    CRYPTO_DES3_EDE_X86_64 = option true;
    CRYPTO_SHA1_SSSE3 = option true;
    CRYPTO_SHA256_SSSE3 = option true;
    CRYPTO_SHA512_SSSE3 = option true;
  } // lib.optionalAttrs hostPlatform.isRiscV64 {
    CRYPTO_AES_RISCV64 = option true;
    CRYPTO_SHA256_RISCV64 = option true;
    CRYPTO_SHA512_RISCV64 = option true;
  } // lib.optionalAttrs hostPlatform.isAarch64 {
    CRYPTO_AES_ARM64_CE = option true;
    CRYPTO_AES_ARM64_CE_BLK = option true;
    CRYPTO_SHA1_ARM64_CE = option true;
    CRYPTO_SHA256_ARM64 = option true;
    CRYPTO_SHA2_ARM64_CE = option true;
    CRYPTO_SHA512_ARM64 = option true;
    CRYPTO_SHA512_ARM64_CE = option true;
  };

  audio = {
    SOUND = true;
    SND = true;
    SND_PCM_TIMER = true;
    SND_DYNAMIC_MINORS = true;
    SND_SUPPORT_OLD_API = false;
    SND_PCI = true;

    SND_USB = true;
    SND_USB_AUDIO = true;
  };
}
