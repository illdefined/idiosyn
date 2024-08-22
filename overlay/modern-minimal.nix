{ nixpkgs, ... }: final: prev:

let
  inherit (nixpkgs.lib.lists) remove;
in {
  curl = prev.curl.override {
    gssSupport = false;
    scpSupport = false;
    zstdSupport = true;
  };

  ffmpeg = prev.ffmpeg.override {
    ffmpegVariant = "headless";
    withAlsa = false;
    withSsh = false;
  };

  firefox-unwrapped = prev.firefox-unwrapped.override {
    alsaSupport = false;
    gssSupport = false;
    jemallocSupport = false;
    sndioSupport = false;
  };

  firefox = final.wrapFirefox final.firefox-unwrapped { };

  gst_all_1 = prev.gst_all_1 // {
    gst-plugins-bad = prev.gst_all_1.gst-plugins-bad.overrideAttrs (prevAttrs: {
      mesonFlags = prevAttrs.mesonFlags or [ ]
        ++ [ "-Dcurl-ssh2=disabled" ];
    });
  };

  mesa = (prev.mesa.overrideAttrs (prevAttrs: {
    outputs = remove "spirv2dxil" prevAttrs.outputs;
  })).override {
    galliumDrivers = [
      "iris"
      "kmsro"
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

  systemd = prev.systemd.override {
    withApparmor = false;
    withHomed = false;
    withIptables = false;
  };
}
