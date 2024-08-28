{ self, nixpkgs, ... }: final: prev:

let
  inherit (final) system;
  inherit (nixpkgs.lib.attrsets) genAttrs;
  inherit (nixpkgs.lib.lists) remove toList;
  inherit (nixpkgs.lib.strings) mesonBool mesonEnable;
  inherit (self.lib) flags packages;

  final' = final;
  prev' = prev;
in genAttrs [
  "SDL2"
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

  gammastep = prev.gammastep.override {
    withRandr = false;
  };

  gd = prev.gd.override { withXorg = false; };

  gst_all_1 = prev.gst_all_1 // genAttrs [
    "gst-plugins-base"
    "gst-plugins-good"
  ] (pkg: prev.gst_all_1.${pkg}.override { enableX11 = false; }) // {
    gst-vaapi = prev.gst_all_1.gst-vaapi.overrideAttrs (prevAttrs: {
      mesonFlags = prevAttrs.mesonFlags or [ ] ++ [
        (mesonEnable "x11" false)
        (mesonEnable "glx" false)
      ];
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
      |> packages.remove [ "kio" ];
  })).override {
    withKeePassX11 = false;
  };

  libepoxy = (prev.libepoxy.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      ++ [ final.libGL ];
    mesonFlags = prevAttrs.mesonFlags or [ ]
      |> flags.subst { "-Degl=no" = "-Degl=yes"; };
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
    mesonFlags = prevAttrs.mesonFlags or [ ] ++ [
      (mesonEnable "xlib-lease" false)
      (mesonEnable "glx" false)
      (mesonEnable "gallium-vdpau" false)
    ];
  })).override {
    eglPlatforms = [ "wayland" ];
  };

  mpv-unwrapped = prev.mpv-unwrapped.override {
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
          |> flags.remove [ "-DUSE_X11" ];
      };

      configureFlags = prevAttrs.configureFlags or [ ]
        |> flags.remove [ "-qpa xcb" ]
        |> flags.subst { "-xcb" = "-no-xcb"; };
    })).override {
      withGtk3 = false;
      withQttranslation = false;
    };
  });

  w3m = prev.w3m.override {
    x11Support = false;
    imlib2 = final.imlib2;
  };

  utsushi = prev.utsushi.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      |> packages.remove [ "gtkmm" ];
    configureFlags = prevAttrs.configureFlags or [ ]
      |> flags.remove [ "--with-gtkmm" ];
  });

  vim-full = prev.vim-full.override {
    guiSupport = false;
  };

  wayland = prev.wayland.override {
    # broken
    withDocumentation = false;
  };
}
