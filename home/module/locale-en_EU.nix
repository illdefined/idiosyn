{ self, ... }: { lib, pkgs, ... }: {
  home.language.base = lib.mkDefault "en_EU.UTF-8";
  i18n.glibcLocales = self.packages.${pkgs.system}.locale-en_EU;
}
