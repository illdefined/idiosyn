{ ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };

  fira-code-features = [
    "cv01"
    "cv06"
    "onum"
    "ss01"
    "ss03"
    "ss06"
    "ss07"
    "ss08"
    "zero"
  ];

  cmd = {
    brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
    fish = "${osConfig.programs.fish.package}/bin/fish";
    grim = "${pkgs.grim}/bin/grim -l 9";
    jq = "${config.programs.jq.package}/bin/jq";
    keepassxc = "${pkgs.keepassxc}/bin/keepassxc";
    kill = "${pkgs.procps}/bin/kill";
    kitty = ''${config.programs.kitty.package}/bin/kitty --single-instance --instance-group "$XDG_SESSION_ID"'';
    loginctl = "${osConfig.systemd.package}/bin/loginctl";
    mdless = "${pkgs.mdcat}/bin/mdless";
    mpv = "${config.programs.mpv.package}/bin/mpv";
    pidof = "${pkgs.procps}/bin/pidof";
    playerctl = "${pkgs.playerctl}/bin/playerctl";
    pwvucontrol = "${pkgs.pwvucontrol}/bin/pwvucontrol";
    slurp = "${pkgs.slurp}/bin/slurp";
    swaylock = "${config.programs.swaylock.package}/bin/swaylock";
    swaymsg = "${config.wayland.windowManager.sway.package}/bin/swaymsg";
    swayrbar = "${pkgs.swayrbar.override { withPulseaudio = true; }}/bin/swayrbar";
    tofi-drun = "${config.programs.tofi.package}/bin/tofi-drun";
    wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
    wpctl = "${osConfig.services.pipewire.wireplumber.package}/bin/wpctl";
    xargs = "${pkgs.findutils}/bin/xargs";
    xdg-open = "${pkgs.xdg-utils}/bin/xdg-open";
  };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  fonts.fontconfig = {
    enable = true;

    defaultFonts = {
      sansSerif = [
        "Lato"
        "M PLUS 1"
        "Noto Sans"
        "Symbols Nerd Font"
        "Unifont"
        "Unifont Upper"
      ];

      serif = [ "Noto Serif"];

      monospace = [
        "Fira Code"
        "M PLUS 1 Code"
        "Noto Sans Mono"
        "Symbols Nerd Font Mono"
      ];

      emoji = [ "Noto Color Emoji" ];
    };
  };

  home.file.".xkb/symbols/greedy".source = ./greedy.xkb;

  home.keyboard = {
    layout = "greedy";
    options = [ "ctrl:nocaps" ];
  };

  home.packages = with pkgs; [
    # Founts
    lato
    fira-code
    mplus-outline-fonts.githubRelease
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    noto-fonts
    noto-fonts-color-emoji
    unifont

    # Image processing
    oxipng

    # Documentation
    linux-manual
    man-pages
    man-pages-posix

    # System operations
    restic

    # Cryptography
    rage

    # Messaging
    fractal
    signal-desktop

    # Audio control
    pwvucontrol

    inkscape
    obsidian

    kicad
    calibre
    keepassxc

    # Multimedia
    jellyfin-mpv-shim

    libreoffice
  ];

  programs.beets = {
    enable = true;
    settings = {
      directory = "~/msc";
      import.reflink = "auto";

      plugins = [
        "chroma"
        "spotify"
        "fromfilename"

        "fetchart"
        "lyrics"
        "replaygain"

        "duplicates"
        "hook"
      ];

      hook.hooks = [
        {
          event = "import";
          command = "systemctl --user start mopidy-scan.service";
        }
      ];
    };
  };

  programs.eza.extraOptions = lib.mkAfter [ "--hyperlink" ];

  programs.imv.enable = true;

  programs.kitty = {
    enable = true;
    theme = "Catppuccin-Mocha";
    settings = {
      disable_ligatures = "cursor";

      cursor_blink_interval = 0;

      scrollback_lines = 65536;
      scrollback_fill_enlarged_window = true;

      enable_audio_bell = false;

      close_on_child_death = true;

      clear_all_shortcuts = true;

      # Mouse
      click_interval = "0.2";
    };

    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "ctrl+shift+s" = "paste_from_selection";
      "shift+insert" = "paste_from_selection";
      "ctrl+up" = "scroll_line_up";
      "ctrl+down" = "scroll_line_down";
      "ctrl+page_up" = "scroll_page_up";
      "ctrl+page_down" = "scroll_page_down";
      "shift+page_up" = "scroll_page_up";
      "shift+page_down" = "scroll_page_down";
      "ctrl+home" = "scroll_home";
      "ctrl+end" = "scroll_end";
      "ctrl+print_screen" = "show_scrollback";

      "ctrl+equal" = "change_font_size all 0";
      "ctrl+plus" = "change_font_size all +1";
      "ctrl+minus" = "change_font_size all -1";

      "ctrl+shift+u" = "kitten unicode_input";
    };

    extraConfig = let
      mouse = {
        "left click ungrabbed" = "mouse_handle_click selection prompt";
        "ctrl+left click ungrabbed" = "mouse_handle_click link";

        "left press ungrabbed" = "mouse_selection normal";
        "shift+left press ungrabbed" = "mouse_selection line";
        "ctrl+left press ungrabbed" = "mouse_selection rectangle";

        "left doublepress ungrabbed" = "mouse_selection word";
        "left triplepress ungrabbed" = " mouse_selection line";
      } |> lib.mapAttrsToList (n: v: "mouse_map ${n} ${v}\n")
        |> lib.concatStrings;
    in ''
      clear_all_mouse_actions yes
      ${mouse}
    '';
  };

  programs.mpv = {
    enable = true;
    defaultProfiles = [ "high-quality" ];
    config = {
      #access-references = false;

      # Video output
      vo = "gpu";
      #gpu-api = "vulkan";
      hwdec = "vulkan,vaapi,auto-safe";
      vd-lavc-dr = true;

      scale = "ewa_lanczos4sharpest";
      cscale = "spline64";
      dscale = "mitchell";
      tscale = "oversample";

      # A/V sync
      video-sync = "display-resample";
      interpolation = true;

      # Audio
      volume = 100;
      volume-max = 100;

      # Subtitles
      sub-auto = "fuzzy";

      # Screenshots
      screenshot-format = "avif";

      # Cache
      demuxer-max-bytes = "768MiB";
      demuxer-max-back-bytes = "256MiB";
    };

    profiles = {
      highres = {
        scale = "spline64";
      };
    };

    scripts = with pkgs.mpvScripts; [
      mpris
      autocrop
      autodeint
    ];

    scriptOpts = {
      autocrop.auto = false;
    };
  };

  programs.sioyek = {
    enable = true;
    bindings = {
      "command" = "-";

      "move_up" = [ "<up>" "t" ];
      "move_down" = [ "<down>" "n" ];
      "move_left" = [ "<right>" "h" ];
      "move_right" = [ "<left>" "r" ];
    };
  };

  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      screenshots = true;
      effect-blur = "5x3";
      grace = 2;
    };
  };

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: {
      inherit (tpkgs) 
        texlive-scripts

        xelatex-dev
        fontspec
        polyglossia

        hyphen-english
        hyphen-french
        hyphen-german
        hyphen-portuguese
        hyphen-spanish

        koma-script

        amsmath
        bookmark
        booktabs
        csquotes
        hyperref
        multirow
        paralist
        preprint
        realscripts
        textpos
        unicode-math
        units
        xecjk
        xecolor
        xltxtra
        xtab
      ;
    };
  };

  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird;
    profiles = { };
  };

  programs.tofi = {
    enable = true;
    settings = {
      history = true;
      fuzzy-match = true;
      num-results = 8;

      font = pkgs.runCommand "fount-path" {
        preferLocal = true;
        nativeBuildInputs = with pkgs; [ fontconfig fira-code ];
      } ''
        fc-match -f "%{file}" "Fira Code" >"$out"
      '' |> builtins.readFile |> lib.mkForce;

      font-size = lib.mkForce 14;
      font-features = fira-code-features |> lib.concatStringsSep ",";
      font-variations = "wght 450";
      font-hint = true;

      anchor = "top";
      horizontal = true;

      width = "100%";
      height = 30;

      min-input-width = 120;
      result-spacing = 20;

      border-width = 0;
      outline-width = 0;

      padding-top = 4;
      padding-bottom = 4;
      padding-left = 12;
      padding-right = 12;
    };
  };

  programs.yt-dlp.enable = true;

  services.gammastep = lib.optionalAttrs (osConfig ? location) (
  let inherit (osConfig) location; in {
    inherit (location) provider;
    enable = true;
    settings = {
      general.adjustment-method = "wayland";
    };
  } // lib.optionalAttrs (location.provider == "manual") {
    #inherit (location) latitude longitude;
  });

  services.mako = {
    enable = true;
    defaultTimeout = 5000;
  };

  services.mopidy = {
    enable = true;
    extensionPackages = with pkgs; [
      mopidy-iris
      mopidy-local
      mopidy-mpd
      mopidy-mpris
    ];
    settings = {
      core = {
        cache_dir = "$XDG_CACHE_DIR/mopidy";
        config_dir = "$XDG_CONFIG_DIR/mopidy";
        data_dir = "$XDG_DATA_DIR/mopidy";
      };

      audio.mixer = "none";
      file.media_dirs = [ "$XDG_MUSIC_DIR" ];
      local.media_dir = "$XDG_MUSIC_DIR";

      mpd.hostname = "localhost";

      http = {
        hostname = "localhost";
        port = 6680;
        default_app = "iris";
      };
    };
  };

  services.swayidle = {
    enable = true;
    events = with cmd; [
      { event = "lock"; command = "${swaylock} -f"; }
      { event = "before-sleep"; command = "${loginctl} lock-session"; }
    ];

    timeouts = with cmd; [
      {
        timeout = 210;
        command = "${brightnessctl} --save -e set 20%-";
        resumeCommand = "${brightnessctl} --restore";
      }
      {
        timeout = 240;
        command = "${loginctl} lock-session";
      }
      {
        timeout = 270;
        command = "${swaymsg} output '* dpms off'";
        resumeCommand = "${swaymsg} output '* dpms on'";
      }
    ];
  };

  services.syncthing = {
    enable = true;
    tray.enable = true;
  };

  services.udiskie = {
    enable = true;
    automount = false;
  };

  stylix = {
    enable = true;

    image = ./wallpaper.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
    polarity = "dark";

    opacity = {
      applications = 0.98;
      desktop = 0.98;
      popups = 0.99;
      terminal = 0.98;
    };

    fonts = {
      sansSerif = {
        package = pkgs.lato;
        name = "sans-serif";
      };

      serif = {
        package = pkgs.noto-fonts;
        name = "serif";
      };

      monospace = {
        package = pkgs.fira-code;
        name = "monospace";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "emoji";
      };

      sizes = {
        terminal = 11;
      };
    };
  };

  systemd.user.services = lib.genAttrs [ "syncthing" ] (service: {
    Unit = {
      ConditionACPower = true;
      StopPropagatedFrom = [ "power-external.target" ];
    };
  });

  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    xwayland = false;

    wrapperFeatures = {
      base = true;
      gtk = true;
    };

    systemd.variables = lib.mkAfter [ "PATH" ];

    extraSessionCommands = let
      env = {
        WLR_RENDERER = "vulkan";
        NIXOS_OZONE_WL = 1;
      };
    in env
      |> lib.mapAttrsToList (n: v: "export ${lib.toShellVar n v}\n")
      |> lib.concatStrings;

    config = with cmd; {
      input."*" = {
        xkb_layout = "us,${config.home.keyboard.layout}";
        xkb_options = lib.concatStringsSep ","
          config.home.keyboard.options;
        xkb_switch_layout = "1";
      };

      output = {
        "*" = {
          scale = "1";
          background = "${./wallpaper.png} fill";
          adaptive_sync = "on";
        };

        "Lenovo Group Limited P40w-20 V9084N0R" = {
          resolution = "5120x2160";
          position = "0 0";
          subpixel = "rgb";
        };

        "LG Display 0x06AA Unknown" = {
          position = "0 2160";
          subpixel = "rgb";
        };
      };

      bars = [
        {
          fonts = lib.mkForce {
            names = [ "monospace" ];
            size = 11.0;
          };

          statusCommand = swayrbar;
        }
      ];

      gaps = {
        inner = 4;
        outer = 4;
      };

      window.titlebar = false;

      bindkeysToCode = true;
      modifier = "Mod4";
      terminal = kitty;
      menu = "${tofi-drun} | ${xargs} ${swaymsg} exec --";

      keybindings = let
        mod = config.wayland.windowManager.sway.config.modifier;
      in lib.mkOptionDefault {
        # Workspaces
        "${mod}+Grave" = "workspace number 0";
        "${mod}+Shift+Grave" = "move container to workspace number 0";

        "${mod}+Shift+Return" = "exec ${kitty} ${fish} --private";

        # Function keys
        XF86MonBrightnessUp = "exec ${brightnessctl} -e set +5%";
        XF86MonBrightnessDown = "exec ${brightnessctl} -e set 5%-";
        XF86AudioRaiseVolume = "exec ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ +2dB";
        XF86AudioLowerVolume = "exec ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ -2dB";
        XF86AudioMute = "exec set-mute @DEFAULT_AUDIO_SINK@ toggle";
        XF86AudioMicMute = "exec set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        XF86AudioNext = "exec ${playerctl} next";
        XF86AudioPrev = "exec ${playerctl} previous";
        XF86AudioPlay = "exec ${playerctl} play";
        XF86AudioStop = "exec ${playerctl} pause";
        XF86Explorer = "exec ${xdg-open} https:";

        # Screenshots
        "${mod}+Print" = "exec ${grim} -g - - | ${wl-copy}";
        "${mod}+Shift+Print" = "exec ${slurp} | ${grim} -g - - | ${wl-copy}";
        "${mod}+Ctrl+Print" = ''
          exec ${swaymsg} -t get_tree \
            | ${jq} -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' \
            | ${grim} -g - - \
            | ${wl-copy}
        '';
      };

      startup = [
        { command = "${swaymsg} input '*' xkb_switch_layout 1"; always = true; }
        { command = "${keepassxc}"; }
      ];
    };
  };

  xdg.configFile."fontconfig/conf.d/80-fira-code.conf".text = ''
    <?xml version='1.0'?>
    <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
    <fontconfig>
      <match target="font">
        <test name="family" compare="eq" ignore-blanks="true">
          <string>Fira Code</string>
        </test>
        <edit name="fontfeatures" mode="append">
          ${fira-code-features
            |> map (tag: "<string>${lib.escapeXML tag}</string>")
            |> lib.concatStrings}
        </edit>
      </match>
    </fontconfig>
  '';

  xdg.configFile."kitty/open-actions.conf".text = with cmd; ''
    protocol file
    mime image/*
    action launch --type overlay kitten icat --hold -- "$FILE_PATH"

    protocol file
    mime text/markdown
    action launch --type overlay ${mdless} -- "$FILE_PATH"

    protocol file
    mime text/*
    action launch --type overlay $EDITOR -- "$FILE_PATH"

    protocol file
    mime video/*
    action launch --type background ${mpv} -- "$FILE_PATH"

    protocol file
    mime audio/*
    action launch --type overlay ${mpv} -- "$FILE_PATH"

    protocol
    action launch --type background ${xdg-open} "$FILE_PATH"
  '';

  xdg.desktopEntries = {
    kitty = {
      name = "kitty";
      exec = builtins.replaceStrings [ "$" ] [ ''\\$'' ] cmd.kitty;
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "default-web-browser" = [ "firefox.desktop" ];
      "application/pdf" = [ "sioyek.desktop" ];
    };
  };

  xdg.portal = {
    enable = true;
    config.common.default = [ "wlr" "gtk" ];
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      (xdg-desktop-portal-gtk.override { buildPortalsInGnome = false; })
    ];
  };
}
