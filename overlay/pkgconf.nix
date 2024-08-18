{ ... }:

final: prev: {
  pkg-config = prev.pkg-config.override {
    pkg-config = final.libpkgconf.overrideAttrs (prevAttrs: {
      postInstall = let
        ext = final.hostPlatform.extensions.executable;
      in prevAttrs.postInstall or "" + ''
        ln -s pkgconf${ext} "$out/bin/pkg-config${ext}"
        ln -s pkgconf.1 "$man/share/man/man1/pkg-config.1"
      '';
    });
  };
}
