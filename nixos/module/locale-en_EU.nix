{ self, ... }: { config, lib, pkgs, ... }: {
  i18n.defaultLocale = lib.mkDefault "en_EU.UTF-8";
  i18n.glibcLocales = self.packages.${pkgs.stdenv.hostPlatform.system}.locale-en_EU.override {
    allLocales = builtins.any (x: x == "all") config.i18n.supportedLocales;
    locales = config.i18n.supportedLocales;
  };
}
