{ ... }: { config, lib, pkgs, ... }@args:
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
    package = pkgs.firefox;
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

      # use OS resolver
      "network.trr.mode" = 5;

      # force HTTPS
      "dom.security.https_only_mode" = true;
      "dom.security.https_only_mode_ever_enabled" = true;

      # enable EME
      "media.eme.enabled" = true;

      # founts
      "font.default.x-unicode" = "sans-serif";
      "font.default.x-western" = "sans-serif";
      "font.name.sans-serif.x-unicode" = "Lato";
      "font.name.sans-serif.x-western" = "Lato";
      "font.name.monospace.x-unicode" = "Fira Code";
      "font.name.monospace.x-western" = "Fira Code";

      # hardware acceleration
      "gfx.webrender.all" = true;
      "layers.acceleration.force-enabled" = true;
      "media.ffmpeg.vaapi.enabled" = true;

      # always ask for download location
      "browser.download.useDownloadDir" = false;

      # disable firefox tab
      "browser.tabs.firefox-view" = false;

      # disable firefox intro tab
      "browser.startup.homepage_override.mstone" = "ignore";

      # disable default browser check
      "browser.shell.checkDefaultBrowser" = false;

      # private containor for new tab page thumbnails
      "privacy.usercontext.about_newtab_segregation.enabled" = true;

      # disable Beacons API
      "beacon.enabled" = false;

      # disable pings
      "browser.send_pings" = false;

      # strip query parameters
      "privacy.query_stripping" = true;

      # disable access to device sensors
      "device.sensors.enabled" = false;
      "dom.battery.enabled" = false;

      # disable media auto‐play
      "media.autoplay.enabled" = false;

      # block third‐party cookies
      "network.cookie.cookieBehavior" = 1;

      # spoof referrer header
      "network.http.referer.spoofSource" = true;

      # isolate all browser identifier sources
      "privacy.firstparty.isolate" = true;

      # resist fingerprinting
      #"privacy.resistFingerprinting" = true;

      # enable built‐in tracking protection
      "privacy.trackingprotection.enabled" = true;
      "privacy.trackingprotection.emailtracking.enabled" = true;
      "privacy.trackingprotection.socialtracking.enabled" = true;

      # disable data sharing
      "app.normandy.enabled" = false;
      "app.shield.optoutstudies.enabled" = false;
      "datareporting.healthreport.uploadEnabled" = false;

      # disable safebrowsing
      "browser.safebrowsing.downloads.enabled" = false;
      "browser.safebrowsing.malware.enabled" = false;
      "browser.safebrowsing.phishing.enabled" = false;

      # disable firefox account
      "identity.fxaccounts.enabled" = false;

      # disable sponsored items
      "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      "browser.newtabpage.enhanced" = false;

      # disable Pocket
      "extensions.pocket.enabled" = false;

      # disable crash reporting
      "browser.tabs.crashReporting.sendReport" = false;
      "breakpad.reportURL" = "";

      # disable accessibility services
      "accessibility.force_disabled" = true;

      # disable password auto‐fill
      "signon.autofillForms" = false;

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
