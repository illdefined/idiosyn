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

in genAttrs [
  "cairo"
  "dbus"
  "ghostscript"
  "gobject-introspection"
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

  gtk3 = (prev.gtk3.overrideAttrs (prevAttrs: {
    propagatedBuildInputs = prevAttrs.propagatedBuildInputs or [ ]
      |> removePackages [ "libICE" "libSM" "libX.*" ];
  })).override {
    x11Support = false;
    xineramaSupport = false;
  };

  gtk4 = (prev.gtk4.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      |> removePackages [ "libICE" "libSM" "libX.*" ];
  })).override {
    x11Support = false;
    xineramaSupport = false;
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

  kdePackages = prev.kdePackages.overrideScope (final: prev: {
    kguiaddons = prev.kguiaddons.overrideAttrs (prevAttrs: {
      cmakeFlags = prevAttrs.cmakeFlags or [ ]
        ++ [ "-DWITH_X11:BOOL=OFF" ];
    });
  });

  keepassxc = (prev.keepassxc.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs
      |> removePackages [ "kio" ];
  })).override {
    withKeePassX11 = false;
  };

  kitty = prev.kitty.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      |> removePackages [ "libX.*" ];

    postPatch = prevAttrs.postPatch or "" + ''
      substituteInPlace setup.py \
        --replace-fail "'x11 wayland'" "'wayland'" \
        --replace-fail "'gl'" "'opengl'"

      substituteInPlace kitty_tests/{check_build,glfw}.py \
        --replace-fail "'x11'" "'wayland'"
    '';
  });

  libcanberra = prev.libcanberra.override {
    withAlsa = false;
    gtkSupport = null;
  };

  libcanberra-gtk3 = final.libcanberra.overrideAttrs (prevAttrs: {
    passthru = prevAttrs.passthru or { } // {
      gtkModule = final.emptyDirectory;
    };
  });

  libepoxy = (prev.libepoxy.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      ++ [ final.libGL ];
    mesonFlags = prevAttrs.mesonFlags or [ ]
      |> substituteFlags { "-Degl=.*" = "-Degl=yes"; };
  })).override {
    x11Support = false;
  };

  libGL = prev.libGL.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      |> removePackages [ "libX.*" "xorgproto" ];

    configureFlags = prevAttrs.configureFlags or [ ]
      ++ [ "--disable-x11" ];

    postFixup = null;
  });

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

  libxkbcommon = prev.libxkbcommon.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      |> removePackages [ "libxcb" ];

    mesonFlags = prevAttrs.mesonFlags or [ ]
      ++ [ (mesonBool "enable-x11" false ) ];

    meta = prevAttrs.meta or { } // {
      pkgConfigModules = prevAttrs.meta.pkgConfigModules or [ ]
        |> remove "xkbcommon-x11";
    };
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
          "-opengl .*" = "-opengl es2";
          "-qpa .*" = null;
          "-xcb" = "-no-xcb";
        };
    })).override {
      mysqlSupport = false;
      withGtk3 = false;
      withQttranslation = false;
    };
  });

  qt6 = final.lib.makeOverridable ({ ... }@args: (prev.qt6.override args).overrideScope (final: prev: {
    qtbase = (prev.qtbase.overrideAttrs (prevAttrs: {
      buildInputs = prevAttrs.buildInputs or [ ]
        |> removePackages [ "libX.*" "libxcb" "xcb.*" ];

      cmakeFlags = prevAttrs.cmakeFlags ++ mapAttrsToList
        (f: v: "-DQT_FEATURE_${f}:BOOL=${if v then "ON" else "OFF"}") {
          xcb = false;
          xlib = false;
          vulkan = true;
          wayland = true;
        };
    })).override {
      qttranslations = null;
    };

    qtwebengine = prev.qtwebengine.overrideAttrs (prevAttrs: {
      env = prevAttrs.env or { } // {
        # hacky
        NIX_CFLAGS_COMPILE = toList prevAttrs.env.NIX_CFLAGS_COMPILE or [ ] ++
          [ "-DGL_RGBA8_OES=0x8058" ] |> toString;
      };
    });
  })) { };

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

  utsushi = prev.utsushi.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      |> removePackages [ "gtkmm" ]
      |> concat [ final.libtiff ];
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

  xdg-desktop-portal-gtk = prev.xdg-desktop-portal-gtk.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      |> removePackages [ "gnome-settings-daemon" ];
  });
}
