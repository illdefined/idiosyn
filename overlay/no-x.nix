{ self, nixpkgs, ... }: final: prev:

let
  inherit (final) system;
  inherit (nixpkgs.lib.attrsets) genAttrs;
  inherit (nixpkgs.lib.lists) remove toList;
  inherit (nixpkgs.lib.strings) mesonBool mesonEnable;
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

  libepoxy = (prev.libepoxy.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      ++ [ final.libGL ];
    mesonFlags = prevAttrs.mesonFlags or [ ]
      |> map (flag: if flag == "-Degl=no" then "-Degl=yes" else flag);
  })).override {
    x11Support = false;
  };

  libgnomekbd = prev.libgnomekbd.overrideAttrs (prevAttrs: {
    mesonFlags = prevAttrs.mesonFlags or [ ]
      ++ [ (mesonBool "tests" false) ];
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

  w3m = prev.w3m.override {
    x11Support = false;
    imlib2 = final.imlib2;
  };

  utsushi = prev.utsushi.overrideAttrs (prevAttrs: {
    buildInputs = remove prev.gtkmm2.dev prevAttrs.buildInputs;
    configureFlags = remove "--with-gtkmm" prevAttrs.configureFlags;
  });

  vim-full = prev.vim-full.override {
    guiSupport = false;
  };

  wayland = prev.wayland.override {
    # broken
    withDocumentation = false;
  };
}
