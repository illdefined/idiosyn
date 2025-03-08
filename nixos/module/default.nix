{ self, catppuccin, ... }: { config, lib, pkgs, ... }: {
  imports = [
    catppuccin.nixosModules.catppuccin
  ] ++ (with self.nixosModules; [
    btrfs
    clusters
    datacow
    email
    ephemeral
    kernel
    locale-en_EU
    network
    nix
    openssh
    powersupply
    security
    users
    zram
  ]);

  boot.initrd.systemd.enable = true;
  boot.tmp.useTmpfs = true;

  catppuccin.enable = true;

  documentation = {
    dev.enable = true;
    doc.enable = false;
    info.enable = false;
    man.generateCaches = false;
  };

  environment = {
    binsh = "${pkgs.dash}${pkgs.dash.shellPath}";

    shellAliases = builtins.mapAttrs (name: lib.mkOverride 999) {
      ls = null;
      ll = null;
      l = null;

      lsusb = "cyme --lsusb";
    };

    systemPackages = with pkgs; [
      # Terminfo
      kitty.terminfo

      # Utilities
      (lib.meta.setPrio 0 uutils-coreutils-noprefix)

      # Hardware info
      pciutils
      cyme
    ];
  };

  hardware.block = {
    defaultScheduler = "kyber";
    defaultSchedulerRotational = "bfq";
    scheduler = {
      "mmcblk*" = "bfq";
      "vd[a-z]" = "none";
    };
  };

  hardware.enableRedistributableFirmware = false;
  hardware.firmware = with pkgs; [
    linux-firmware
    #alsa-firmware
    sof-firmware
  ];

  ephemeral.enable = lib.mkDefault true;

  location.provider = lib.mkIf config.hardware.graphics.enable "geoclue2";

  services.dbus.implementation = "broker";
  services.lvm.enable = lib.mkDefault false;

  system.etc.overlay.enable = true;

  system.stateVersion = "25.05";

  time.timeZone = lib.mkDefault "CET";

  users.mutableUsers = false;
}
