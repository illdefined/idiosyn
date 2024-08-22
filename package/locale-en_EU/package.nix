{ ... }: { pkgs, lib, callPackage, allLocales ? false, locales ? [ "en_EU.UTF-8/UTF-8" ] }:

let glibcLocales = callPackage
  (pkgs.path + "/pkgs/development/libraries/glibc/locales.nix")
  { inherit allLocales locales; };
in glibcLocales.overrideAttrs (prevAttrs: {
  postPatch = prevAttrs.postPatch + ''
    cp ${./en_EU} localedata/locales/en_EU
    echo 'en_EU.UTF-8/UTF-8 \' >>localedata/SUPPORTED
  '';

  meta = prevAttrs.meta // {
    maintainers = with lib.maintainers; [ mvs ];
    platforms = prevAttrs.meta.platforms or lib.platforms.linux;
  };
})
