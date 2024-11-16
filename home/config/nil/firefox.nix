{ firefox, ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };

  firefox-csshacks = pkgs.fetchFromGitHub {
    owner = "MrOtherGuy";
    repo = "firefox-csshacks";
    rev = "7eca4b1050c4065130a2cf696302b4ef5d88d932";
    sparseCheckout = [ "!/*" "/chrome" "/content" ];
    hash = "sha256-rk0jC5AMw41xt5yItY7CAxuYAFhoe5Jy2tvwgh59cPI=";
  };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  programs.firefox = {
    enable = true;
    package = firefox.packages.${pkgs.system}.firefox;
    profiles = let
    extensions = with config.nur.repos.rycee.firefox-addons; [
      clearurls
      consent-o-matic
      decentraleyes
      keepassxc-browser
      multi-account-containers
      ublock-origin
    ];
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

      # enable user profile customisation
      "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    };
    userChrome = lib.concatMapStrings (css:
      "@import url('${firefox-csshacks}/chrome/${css}.css');\n"
      ) [
        "hide_tabs_with_one_tab"
        "autohide_bookmarks_and_main_toolbars"
      ];
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
        inherit extensions settings userChrome search;
        isDefault = true;
      };
      sneaky = {
        inherit extensions settings userChrome search;
        id = 1;
      };
      vanilla = {
        inherit userChrome search;
        id = 2;
      };
    };
  };

  xdg.mimeApps.defaultApplications = {
    default-web-browser = [ "firefox.desktop" ];
  };
}
