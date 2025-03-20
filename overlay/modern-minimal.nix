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
  alsa-ucm-conf = prev.alsa-ucm-conf.overrideAttrs (prevAttrs: {
    src = final.fetchFromGitHub {
      owner = "illdefined";
      repo = "alsa-ucm-conf";
      rev = "fb1239d1a1e56bf51da23bce0d3c4b93b7d7b56f";
      hash = "sha256-5rHOZbRJEHkHORTERBli20ivHDcDJ8ssNa6TZExoyNs=";
    };
  });

  xvfb-run = self.packages.${system}.wayland-headless;

  beam = prev.beam_nox;
  graphviz = prev.graphviz-nox;
  jdk8 = prev.jdk8_headless;
  jre8 = prev.jre8_headless;
  openjdk8 = prev.openjdk_headless;

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

  gd = prev.gd.override { withXorg = false; };

  imagemagick = prev.imagemagick.override {
    libX11Support = false;
    libXtSupport = false;
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

  libsecret = prev.libsecret.override { withTpm2Tss = true; };

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

  svt-av1 = final.svt-av1-psy;

  systemd = prev.systemd.override {
    withApparmor = false;
    withHomed = false;
    withIptables = false;
  };

  w3m = prev.w3m.override {
    x11Support = false;
    imlib2 = final.imlib2;
  };
}
