{ nixpkgs, ... }: final: prev:

let
  inherit (nixpkgs.lib.attrsets) genAttrs;
in genAttrs [
  "SDL2"
  "firefox-unwrapped"
  "mpv-unwrapped"
] (pkg: prev.${pkg}.override { alsaSupport = false; })
// genAttrs [
  "ffmpeg"
  "libcanberra"
] (pkg: prev.${pkg}.override { withAlsa = false; })
// {
  firefox = final.wrapFirefox final.firefox-unwrapped { };

  mpv = final.mpv-unwrapped.wrapper {
    mpv = final.mpv-unwrapped;
  };
}
