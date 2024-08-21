{ nixpkgs, ... }: final: prev: {
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

  mesa = prev.mesa.override {
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

  foo = null;
}
