{ self, nixpkgs, ... }: final: prev:

let
  inherit (final) system;
  inherit (nixpkgs.lib.attrsets) genAttrs mapAttrsToList;
  inherit (nixpkgs.lib.lists) remove subtractLists toList;
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

  mpv-unwrapped = prev.mpv-unwrapped.override {
    alsaSupport = false;
    cacaSupport = false;
    openalSupport = false;
    sdl2Support = false;
    vdpauSupport = false;
    x11Support = false;
  };

  mpv = final.mpv-unwrapped.wrapper {
    mpv = final.mpv-unwrapped;
  };

  opensc = prev.opensc.overrideAttrs (prevAttrs: {
    version = "0.26.1-unstable-2025-09-15";

    src = final.fetchFromGitHub {
      inherit (prevAttrs.src) owner repo;
      rev = "92fe011a9cc5e03a1c9a2127d33b603e6d24907e";
      hash = "sha256-VWbpRmt3XYXsHyXbv1NIW+sMzevxtOPKmyv6DRuatGo=";
    };
  });

  pipewire = prev.pipewire.overrideAttrs(prevAttrs: {
    mesonFlags = prevAttrs.mesonFlags or [ ] ++ [ (mesonEnable "selinux" false) ];
  });

  svt-av1 = final.svt-av1-psy;

  systemd = prev.systemd.override {
    withApparmor = false;
    withHomed = false;
  };

  w3m = prev.w3m.override {
    x11Support = false;
    imlib2 = final.imlib2;
  };
}
