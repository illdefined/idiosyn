{ self, nixpkgs, ... }: final: prev:

let
  inherit (final) system;
  inherit (nixpkgs.lib.attrsets) genAttrs;
  inherit (nixpkgs.lib.lists) remove;
  inherit (nixpkgs.lib.strings) mesonBool mesonEnable;
  inherit (self.lib) substituteFlags removePackages;

  final' = final;
  prev' = prev;

in genAttrs [
  "cairo"
  "dbus"
  "ghostscript"
  "gobject-introspection"
  "gtk3"
  "gtk4"
  "imlib2"
  "libcaca"
  "pango"
  "pipewire"
] (pkg: prev.${pkg}.override { x11Support = false; })

// genAttrs [
  "intel-media-driver"
  "mupdf"
] (pkg: prev.${pkg}.override { enableX11 = false; })

// genAttrs [
  "hyprland"
  "sway"
  "sway-unwrapped"
  "swayfx"
  "swayfx-unwrapped"
  "wlroots"
] (pkg: prev.${pkg}.override { enableXWayland = false; })

// {
  xvfb-run = self.packages.${system}.wayland-headless;

  beam = prev.beam_nox;
  graphviz = prev.graphviz-nox;
  jdk8 = prev.jdk8_headless;
  jre8 = prev.jre8_headless;
  openjdk8 = prev.openjdk_headless;

  SDL2 = prev.SDL2.override {
    alsaSupport = false;
    x11Support = false;
  };

  curl = prev.curl.override {
    gssSupport = false;
    scpSupport = false;
    zstdSupport = true;
  };

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

  evolution = prev.evolution.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      |> removePackages [ "libcanberra" ];

    cmakeFlags = prevAttrs.cmakeFlags or [ ]
      ++ [ "-DENABLE_CANBERRA:BOOL=OFF" ];
    });

  evolution-data-server = prev.evolution-data-server.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      |> removePackages [ "libcanberra" ];

    cmakeFlags = prevAttrs.cmakeFlags or [ ]
      |> substituteFlags { "-DENABLE_CANBERRA[:=].*" = "-DENABLE_CANBERRA:BOOL=OFF"; };
  });

  ffmpeg = prev.ffmpeg.override {
    ffmpegVariant = "headless";
    withAlsa = false;
    withSsh = false;
  };

  firefox-unwrapped = (prev.firefox-unwrapped.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      ++ [ final.alsa-lib ];

    configureFlags = prevAttrs.configureFlags or [ ]
      |> substituteFlags {
        "--enable-default-toolkit=.*" = "--enable-default-toolkit=cairo-gtk3-wayland-only";
      };
  })).override {
    alsaSupport = false;
    gssSupport = false;
    jemallocSupport = false;
    sndioSupport = false;
  };

  firefox = final.wrapFirefox final.firefox-unwrapped { };

  gammastep = prev.gammastep.override {
    withRandr = false;
  };

  gd = prev.gd.override { withXorg = false; };

  gst_all_1 = prev.gst_all_1 // (genAttrs [
    "gst-plugins-base"
    "gst-plugins-good"
  ] (pkg: prev.gst_all_1.${pkg}.override { enableX11 = false; }) // {
    gst-vaapi = prev.gst_all_1.gst-vaapi.overrideAttrs (prevAttrs: {
      mesonFlags = prevAttrs.mesonFlags or [ ] ++ [
        (mesonEnable "x11" false)
        (mesonEnable "glx" false)
      ];
    });
  }) // {
    gst-plugins-bad = prev.gst_all_1.gst-plugins-bad.overrideAttrs (prevAttrs: {
      mesonFlags = prevAttrs.mesonFlags or [ ]
        ++ [ "-Dcurl-ssh2=disabled" ];
    });
  };

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

  keepassxc = (prev.keepassxc.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs
      |> removePackages [ "kio" ];
  })).override {
    withKeePassX11 = false;
  };

  libcanberra = prev.libcanberra.override {
    withAlsa = false;
    gtkSupport = null;
  };

  libepoxy = (prev.libepoxy.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      ++ [ final.libGL ];
    mesonFlags = prevAttrs.mesonFlags or [ ]
      |> substituteFlags { "-Degl=.*" = "-Degl=yes"; };
  })).override {
    x11Support = false;
  };

  libgnomekbd = prev.libgnomekbd.overrideAttrs (prevAttrs: {
    mesonFlags = prevAttrs.mesonFlags or [ ]
      ++ [ (mesonBool "tests" false) ];
    });

  libsForQt5 = prev.libsForQt5.overrideScope (final: prev: {
    inherit (final') qt5;

    kguiaddons = prev.kguiaddons.overrideAttrs (prevAttrs: {
      cmakeFlags = prevAttrs.cmakeFlags or [ ]
        ++ [ "-DWITH_X11:BOOL=OFF" ];
    });
  });

  mesa = (prev.mesa.overrideAttrs (prevAttrs: {
    outputs = remove "spirv2dxil" prevAttrs.outputs;

    mesonFlags = prevAttrs.mesonFlags or [ ] ++ [
      (mesonEnable "xlib-lease" false)
      (mesonEnable "glx" false)
      (mesonEnable "gallium-vdpau" false)
    ];
  })).override {
    galliumDrivers = [
      "iris"
      "nouveau"
      "radeonsi"
      "swrast"
      "zink"
    ];

    vulkanDrivers = [
      "amd"
      "intel"
      "nouveau"
      "swrast"
    ];

    eglPlatforms = [ "wayland" ];
  };

  mpv-unwrapped = prev.mpv-unwrapped.override {
    alsaSupport = false;
    cacaSupport = false;
    openalSupport = false;
    sdl2Support = false;
    vdpauSupport = false;
    x11Support = false;
    xineramaSupport = false;
    xvSupport = false;
  };

  mpv = final.mpv-unwrapped.wrapper {
    mpv = final.mpv-unwrapped;
  };

  qt5 = prev.qt5.overrideScope (final: prev: {
    qtbase = (prev.qtbase.overrideAttrs (prevAttrs: {
      env = prevAttrs.env or { } // {
        NIX_CFLAGS_COMPILE = prevAttrs.env.NIX_CFLAGS_COMPILE or ""
          |> substituteFlags { "-DUSE_X11" = null; };
      };

      configureFlags = prevAttrs.configureFlags or [ ]
        |> substituteFlags {
          "-qpa .*" = null;
          "-xcb" = "-no-xcb";
        };
    })).override {
      mysqlSupport = false;
      withGtk3 = false;
      withQttranslation = false;
    };
  });

  systemd = prev.systemd.override {
    withApparmor = false;
    withHomed = false;
    withIptables = false;
  };

  thunderbird-unwrapped = (prev.thunderbird-unwrapped.overrideAttrs (prevAttrs: {
    configureFlags = prevAttrs.configureFlags or [ ]
      |> substituteFlags {
        "--enable-default-toolkit=.*" = "--enable-default-toolkit=cairo-gtk3-wayland-only";
      };
  })).override {
    jemallocSupport = false;
  };

  thunderbird = final.wrapThunderbird final.thunderbird-unwrapped { };

  w3m = prev.w3m.override {
    x11Support = false;
    imlib2 = final.imlib2;
  };

  utsushi = prev.utsushi.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      |> removePackages [ "gtkmm" ];
    configureFlags = prevAttrs.configureFlags or [ ]
      |> substituteFlags { "--with-gtkmm" = null; };
  });

  vim-full = prev.vim-full.override {
    guiSupport = false;
  };

  wayland = prev.wayland.override {
    # broken
    withDocumentation = false;
  };
}
