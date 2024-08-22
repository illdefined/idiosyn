{ nixpkgs, ... }: final: prev:

let
  inherit (nixpkgs.lib.attrsets) genAttrs;
in genAttrs [
  "SDL2"
  "mpv-unwrapped"
] (pkg: prev.${pkg}.override { alsaSupport = false; })
// genAttrs [
  "ffmpeg"
  "libcanberra"
] (pkg: prev.${pkg}.override { withAlsa = false; })
// {
  firefox-unwrapped = (prev.firefox-unwrapped.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      ++ [ final.alsa-lib ];
  })).override {
    alsaSupport = false;
  };

  firefox = final.wrapFirefox final.firefox-unwrapped { };

  mpv = final.mpv-unwrapped.wrapper {
    mpv = final.mpv-unwrapped;
  };
}
