{ self, nixpkgs, ... }: final: prev:

let
  inherit (final.stdenv) hostPlatform;
  inherit (nixpkgs.lib.attrsets) genAttrs mapAttrsToList;
  inherit (nixpkgs.lib.lists) optionals remove subtractLists toList;
  inherit (nixpkgs.lib.strings) mesonBool mesonEnable;
  inherit (nixpkgs.lib.trivial) concat;
  inherit (self.lib) substituteFlags removePackages;

  final' = final;
  prev' = prev;

in {
  libselinux = null;
  networkmanager = null;

  bubblewrap = prev.bubblewrap.overrideAttrs (prevAttrs : {
    mesonFlags = prevAttrs.mesonFlags or [ ] ++ [ (mesonEnable "selinux" false) ];
  });

  electron = prev.electron.override {
    electron-unwrapped = prev.electron.unwrapped.overrideAttrs (prevAttrs: {
      gnFlags = prevAttrs.gnFlags or "" + ''
        # Disable X11
        ozone_platform_x11 = false

        # Disable internal memory allocator
        use_partition_alloc_as_malloc = false
        enable_backup_ref_ptr_support = false
        enable_pointer_compression_support = false
      '';
    });
  };

  gammastep = prev.gammastep.override {
    withRandr = false;
  };

  glib = prev.glib.overrideAttrs(prevAttrs: {
    mesonFlags = prevAttrs.mesonFlags or [ ] ++ [ (mesonEnable "selinux" false) ];
  });

  gnome-keyring = prev.gnome-keyring.overrideAttrs(prevAttrs: {
    mesonFlags = prevAttrs.mesonFlags or [ ] ++ [ (mesonEnable "selinux" false) ];
  });

  gnome-settings-daemon = final.stdenv.mkDerivation {
    pname = "gnome-settings-daemon-stub";
    version = "0";

    buildCommand = ''
      mkdir -p "$out/share/gsettings-schemas"
    '';
  };

  imv = (prev.imv.overrideAttrs(prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      ++ [ final.libGL ];
  })).override {
    withWindowSystem = "wayland";
  };

  inkscape = prev.inkscape.overrideAttrs (prevAttrs: {
    cmakeFlags = prevAttrs.cmakeFlags or [ ]
      ++ [ "-DWITH_X11:BOOL=OFF" ];
  });

  mesa = (prev.mesa.override {
    galliumDrivers = [
      "llvmpipe"
      "virgl"
      "zink"

      "asahi"
      "freedreno"

      "iris"
      "nouveau"
      "radeonsi"
    ];

    vulkanDrivers = [
      "swrast"
      "virtio"

      "asahi"
      "freedreno"

      "amd"
      "intel"
      "nouveau"
    ];
  }).overrideAttrs (prevAttrs: {
    outputs = remove "spirv2dxil" prevAttrs.outputs;
  });

  mpv-unwrapped = prev.mpv-unwrapped.override {
    alsaSupport = false;
    cacaSupport = false;
    openalSupport = false;
    sdl2Support = false;
    vdpauSupport = false;
    x11Support = false;
  };

  nix = final.lixPackageSets.stable.lix;

  opensc = prev.opensc.overrideAttrs (prevAttrs: {
    version = "0.27.0-rc2";

    src = prevAttrs.src.overrideAttrs {
      hash = "sha256-xcfsrG38GdQt/2EbU6rnvQGq6qx/K1SoHhY3yN5AFEc=";
    };
  });

  pipewire = prev.pipewire.overrideAttrs(prevAttrs: {
    mesonFlags = prevAttrs.mesonFlags or [ ] ++ [ (mesonEnable "selinux" false) ];
  });

  qemu-user =
    let
      targets = suffix: map (arch: "${arch}-${suffix}") [
        "aarch64"
        "riscv64"
        "x86_64"
        "i386"
      ];
    in prev.qemu-user.override {
      hostCpuTargets = optionals hostPlatform.isLinux (targets "linux-user")
        ++ optionals hostPlatform.isBSD (targets "bsd-user");
    };

  systemd = prev.systemd.override {
    withApparmor = false;
    withHomed = false;
  };

  w3m = prev.w3m.override {
    x11Support = false;
    imlib2 = final.imlib2;
  };
}
