{ nixpkgs, ... }: final: prev:

let
  inherit (nixpkgs) lib;
in {
  mimalloc = (prev.mimalloc.overrideAttrs (prevAttrs: {
    postPatch = prevAttrs.postPatch or "" + ''
      sed -E -i \
        -e 's/(\{ )1(, UNINIT, MI_OPTION_LEGACY\(purge_decommits,reset_decommits\) \})/\10\2/' \
        -e 's/(\{ )0(, UNINIT, MI_OPTION_LEGACY\(allow_large_os_pages,large_os_pages\) \})/\11\2/' \
        -e 's/(\{ )10(,  UNINIT, MI_OPTION_LEGACY\(purge_delay,reset_delay\) \})/\150\2/' \
        src/options.c
    '';
  })).override {
    secureBuild = true;
  };

  firefox = (final.wrapFirefox final.firefox-unwrapped { }).overrideAttrs (prevAttrs: {
    buildCommand = prevAttrs.buildCommand + ''
      sed -i \
        '$i export MIMALLOC_RESERVE_HUGE_OS_PAGES=2' \
        "$out/bin/firefox"
    '';
  });
  
  thunderbird = (final.wrapThunderbird final.thunderbird-unwrapped { }).overrideAttrs (prevAttrs: {
    buildCommand = prevAttrs.buildCommand + ''
      sed -i \
        '$i export MIMALLOC_RESERVE_HUGE_OS_PAGES=2' \
        "$out/bin/thunderbird"
    '';
  });
  
  mpv = final.mpv-unwrapped.wrapper {
    mpv = final.mpv-unwrapped;
    extraMakeWrapperArgs = [ "--set" "MIMALLOC_RESERVE_HUGE_OS_PAGES" "1" ];
  };
} // lib.genAttrs [
  "bat"
  "bottom"
  "cryptsetup"
  "dbus-broker"
  "fd"
  "firefox-unwrapped"
  "fractal"
  "fuzzel"
  "helix"
  "kitty"
  "mako"
  "mpv-unwrapped"
  "niri"
  "nix"
  "nushell"
  "openssh"
  "pipewire"
  "pueue"
  "ripgrep"
  "sd"
  "sioyek"
  "sudo-rs"
  "systemd"
  "swayidle"
  "swaylock"
  "swaylock-effects"
  "thunderbird-unwrapped"
  "uutils-coreutils"
  "uutils-coreutils-noprefix"
  "waybar"
  "wirepluber"
  "xdg-desktop-portal-gnome"
  "xdg-desktop-portal-gtk"
] (pkg: prev.${pkg}.overrideAttrs (prevAttrs: {
  buildInputs = prevAttrs.buildInputs or [ ] ++ [ final.mimalloc ];
  env = prevAttrs.env or { } // lib.optionalAttrs (prevAttrs ? env.NIX_LDFLAGS) {
    NIX_LDFLAGS = toString (lib.toList prevAttrs.env.NIX_LDFLAGS or [ ] ++ [ "-lmimalloc" ]);
  };

  NIX_RUSTFLAGS = lib.toList prevAttrs.NIX_RUSTFLAGS or [ ] ++ [ "-C link-arg=-lmimalloc" ];
} // lib.optionalAttrs (!prevAttrs ? env.NIX_LDFLAGS) {
  NIX_LDFLAGS = lib.toList prevAttrs.NIX_LDFLAGS or [ ] ++ [ "-lmimalloc" ];
}))
