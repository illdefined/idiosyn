{ firefox, ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  programs.floorp = {
    enable = true;
    package = firefox.packages.${pkgs.system}.floorp;
    languagePacks = [ "en-GB" ];
    profiles = let
    settings = {
      # use OS locale
      "intl.regional_prefs.use_os_locales" = true;

      # localisation
      "intl.accept_languages" = "en-gb,en,de,fr,es-es,es,pt,ja";
      "intl.locale.requested" = "en-GB,en,de,fr,es-ES,es,pt,ja";

      # founts
      "font.default.x-unicode" = "sans-serif";
      "font.default.x-western" = "sans-serif";
      "font.name.sans-serif.x-unicode" = "Lato";
      "font.name.sans-serif.x-western" = "Lato";
      "font.name.monospace.x-unicode" = "Fira Code";
      "font.name.monospace.x-western" = "Fira Code";

      # hardware acceleration
      "layers.acceleration.force-enabled" = true;

      # always ask for download location
      "browser.download.useDownloadDir" = false;

      # private containor for new tab page thumbnails
      "privacy.usercontext.about_newtab_segregation.enabled" = true;

      # disable access to device sensors
      "device.sensors.enabled" = false;
      "dom.battery.enabled" = false;

      # disable media auto‐play
      "media.autoplay.enabled" = false;

      # disable password auto‐fill
      "signon.autofillForms" = false;

      # enable user profile customisation
      "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    };
    search = {
      default = "Google Search";
      force = true;
      engines = {
        "Google Search" = {
          urls = [{ template = "https://www.google.com/search?q={searchTerms}"; }];
          definedAliases = [ "g" ];
        };

        "Nix Packages" = {
          urls = [{
            template = "https://search.nixos.org/packages";
            params = [
              { name = "channel"; value = "unstable"; }
              { name = "type"; value = "packages"; }
              { name = "query"; value = "{searchTerms}"; }
            ];
          }];

          definedAliases = [ "np" ];
        };

        "Gentoo Packages" = {
          urls = [{ template = "https://packages.gentoo.org/packages/search?q={searchTerms}"; }];
          definedAliases = [ "gp" ];
        };

        "Alpine Packages" = {
          urls = [{ template = "https://pkgs.alpinelinux.org/packages?name={searchTerms}"; }];
          definedAliases = [ "ap" ];
        };

        "NixOS Wiki" = {
          urls = [{ template = "https://nixos.wiki/index.php?search={searchTerms}"; }];
          definedAliases = [ "nw" ];
        };

        "Wikipedia (eng)" = {
          urls = [{ template = "https://en.wikipedia.org/wiki/Special:Search?search={searchTerms}"; }];
          definedAliases = [ "w" ];
        };

        "Wikipedia (deu)" = {
          urls = [{ template = "https://de.wikipedia.org/wiki/Spezial:Suche?search={searchTerms}"; }];
          definedAliases = [ "wd" ];
        };

        "Wiktionary (eng)" = {
          urls = [{ template = "https://en.wiktionary.org/wiki/Special:Search?search={searchTerms}"; }];
          definedAliases = [ "k" ];
        };

        "Wiktionary (deu)" = {
          urls = [{ template = "https://de.wiktionary.org/wiki/Spezial:Suche?search={searchTerms}"; }];
          definedAliases = [ "kd" ];
        };

        "Linguee (en‐de)" = {
          urls = [{ template = "https://www.linguee.com/english-german/search?query={searchTerms}"; }];
          definedAliases = [ "en" ];
        };

        "Linguee (en‐fr)" = {
          urls = [{ template = "https://www.linguee.com/english-french/search?query={searchTerms}"; }];
          definedAliases = [ "fr" ];
        };

        "Linguee (en‐es)" = {
          urls = [{ template = "https://www.linguee.com/english-spanish/search?query={searchTerms}"; }];
          definedAliases = [ "es" ];
        };

        "Linguee (en‐pt)" = {
          urls = [{ template = "https://www.linguee.com/english-portuguese/search?query={searchTerms}"; }];
          definedAliases = [ "pt" ];
        };

        "Jisho" = {
          urls = [{ template = "https://jisho.org/search/{searchTerms}"; }];
          definedAliases = [ "ja" ];
        };

        "DeepL" = {
          urls = [{ template = "https://www.deepl.com/translator#en//{searchTerms}"; }];
          definedAliases = [ "dpl" ];
        };
      };
    };
    in {
      default = {
        inherit settings search;
        isDefault = true;
      };
      sneaky = {
        inherit settings search;
        id = 1;
      };
    };
  };

  xdg.mimeApps.defaultApplications = {
    default-web-browser = [ "floorp.desktop" ];
  };
}
