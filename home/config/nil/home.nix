{ self, catppuccin, nix-index-database, niri, ripgrep-all, ... }:
{ config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };

  bat = lib.getExe config.programs.bat.package;
  col = lib.getExe' pkgs.util-linux "col";
  ov = lib.getExe pkgs.ov;
  nix-locate = lib.getExe' config.programs.nix-index.package "nix-locate";
  nu = lib.getExe config.programs.nushell.package;
  sh = lib.getExe self.packages.${pkgs.system}.hush;
in {
  imports = [
    self.homeModules.greedy
    self.homeModules.locale-en_EU
    self.homeModules.ausweisapp
    catppuccin.homeModules.catppuccin
    niri.homeModules.config
  ] ++ self.lib.mods [
    ./gammarelay.nix
    ./founts.nix
    ./editor.nix
    ./desktop.nix
    ./bar.nix
    ./terminal.nix
    ./secrets.nix
    ./goldwarden.nix
    ./floorp.nix
    ./sioyek.nix
    ./texlive.nix
    ./mpv.nix
    ./music.nix
    ./yazi.nix
  ];

  home.stateVersion = "25.05";
  home.enableNixpkgsReleaseCheck = false;

  catppuccin = {
    enable = true;
    cursors.enable = true;
  };

  home.file.".nix-defexpr/channels/nixpkgs/programs.sqlite".source =
    nix-index-database.packages.${pkgs.system}.nix-channel-index-programs;

  home.packages = with pkgs; [
    # Terminfo
    kitty.terminfo

    # Minimal POSIX shell
    self.packages.${system}.hush

    # Core utilities
    (lib.meta.setPrio 0 uutils-coreutils-noprefix)

    # Text manipulation
    delta
    sd
    skim

    # Networking
    dogdns
    whois
    xh

    # Filesystem
    file
    xcp

    # Development
    pijul

    # Calculator
    fend

    jaq

    ripgrep-all.packages.${system}.default

    # Carapace
    carapace-bridge
    sqlite
  ];

  home.activation = let
    inherit (lib) escapeShellArg;
  in {
    cachedir-tag = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run eval echo -n \'Signature: 8a477f597d28d172789f06886806bc55\' \
        \>${escapeShellArg (escapeShellArg config.xdg.cacheHome)}/CACHEDIR.TAG
    '';
  };

  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        indent_style = "tab";
        tab_width = 4;
        end_of_line = "lf";
        charset = "utf-8";
        trim_trailing_whitespace = true;
        insert_final_newline = true;
      };

      "*.nix" = {
        indent_style = "space";
        indent_size = 2;
      };
    };
  };

  home.preferXdgDirectories = true;

  home.sessionVariables = let
    ls-colours = pkgs.runCommand "ls-colours" { } ''
      ${lib.getExe pkgs.vivid} generate catppuccin-mocha >$out
    '';
  in {
    CARAPACE_BRIDGES = "bash";
    LS_COLORS = "$(<${ls-colours})";
    MANROFFOPT = "-c";
    MANPAGER = "${sh} -c '${col} -bx | ${bat} -l man -p'";
    NIX_PATH = "nixpkgs=flake:nixpkgs";
    PAGER = "${ov}";
    SECRET_BACKEND = "file";
    TMPDIR = "$XDG_RUNTIME_DIR/tmp";
    XDG_CONFIG_HOME = "\${XDG_CONFIG_HOME:-$HOME/.config}";
    XDG_CACHE_HOME = "\${XDG_CACHE_HOME:-$HOME/.cache}";
    XDG_STATE_HOME = "\${XDG_STATE_HOME:-$HOME/.local/state}";
  };

  home.shell.enableNushellIntegration = true;

  i18n.glibcLocales = self.packages.${pkgs.system}.locale-en_EU.override {
    locales = [
      "en_EU.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  } |> lib.mkForce;

  programs.aria2 = {
    enable = true;
    settings = {
      max-concurrent-downloads = 4;
      max-connection-per-server = 2;
      min-split-size = "16M";
      remote-time = true;
      split = 4;
      http-accept-gzip = true;
      max-overall-upload-limit = "256K";
      dscp = 8;
      enable-mmap = true;
      file-allocation = "falloc";
    };
  };

  programs.bat = {
    enable = true;
    config = {
      style = lib.concatStringsSep "," [
        "numbers"
        "changes"
        "rule"
        "snip"
      ];

      set-terminal-title = true;

      italic-text = "always";
      nonprintable-notation = "unicode";
      tabs = "0";
      wrap = "never";

      pager = "${ov} -F";
    };
  };

  programs.bottom = {
    enable = true;
    settings.flags = {
      group = true;
      battery = true;
      mem_as_value = true;
      network_use_binary_prefix = true;
      network_use_bytes = true;
    };
  };

  programs.carapace.enable = true;

  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;

    extraOptions = [
      "--binary"
      "--colour=automatic"
      "--colour-scale=all"
      "--colour-scale-mode=gradient"
      "--group-directories-first"
    ];
  };

  programs.fd = {
    enable = true;
    extraOptions = [
      "--hyperlink=auto"
    ];
  };

  programs.git = let
    key = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAICczPHRwY9MAwDGlcB0QgMOJjcpLJhVU3covrW9RBS62AAAABHNzaDo=";
  in {
    enable = true;
    delta.enable = true;

    userName = "Mikael Voss";
    userEmail = "mvs@nyantec.com";

    signing = {
      key = "key::${key}";
      format = "ssh";
      signByDefault = true;
    };

    extraConfig = {
      core = {
        eol = "lf";
        fsync = "committed";
      };

      init = {
        defaultBranch = "main";
      };

      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;

      gpg.ssh.allowedSignersFile = toString (pkgs.writeText "allowed-signers" ''
        ${config.programs.git.userEmail} ${key}
      '');
    };
  };

  programs.man.generateCaches =
    osConfig.documentation.man.generateCaches or false;

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--hyperlink-format=default"
    ];
  };

  programs.ssh = {
    enable = true;
    compression = true;

    controlMaster = "auto";
    controlPath = "\${XDG_RUNTIME_DIR}/ssh/%r@%n:%p";
    controlPersist = "10m";

    matchBlocks = {
      "*.nyantec.com".user = "mvs";
      "solitary.social" = {
        user = "nil";
        forwardAgent = true;
      };
    };

    serverAliveInterval = 10;
    serverAliveCountMax = 60;
  };

  programs.nushell = let
    inherit (lib.hm.nushell) mkNushellInline;
  in {
    enable = true;

    shellAliases = {
      cp = "xcp --workers 0 --driver parblock --fsync";
    };

    environmentVariables = {
      PROMPT_COMMAND = mkNushellInline ''{
        let dir = match (do --ignore-errors { $env.PWD | path relative-to $nu.home-path }) {
          null => $env.PWD
          "" => '~'
          $relative_pwd => ([~ $relative_pwd] | path join)
        }

        [
          (if (is-admin) { ansi red_bold } else { ansi green_bold })
          (sys host | get hostname)
          (char space)
          (ansi blue_bold)
          ($dir | path split | last)
          (ansi reset)
          (char space)
        ] | str join
      }'';

      PROMPT_COMMAND_RIGHT = mkNushellInline ''{
        [
          (ansi light_red)
          ($env.CMD_DURATION_MS | into int | into duration --unit ms)
        ] | str join
      }'';

      PROMPT_INDICATOR = mkNushellInline ''{ "› " }'';
    };

    settings = {
      show_banner = false;

      history = {
        max_size = 131072;
        sync_on_enter = true;
        file_format = "sqlite";
        isolation = true;
      };

      use_kitty_protocol = true;

      keybindings = [
        {
          name = "completion_menu";
          modifier = "control";
          keycode = "char_i";
          mode = [ "emacs" "vi_normal" "vi_insert" ];
          event = {
            until = [
              { send = "menu"; name = "completion_menu"; }
              { send = "menunext"; }
              { edit = "complete"; }
            ];
          };
        }
      ];

      hooks = {
        command_not_found = mkNushellInline ''{
          |cmd_name| (
            try {
              let pkgs = (
                `${nix-locate}`
                --db `${nix-index-database.packages.${pkgs.system}.nix-index-database}`
                --top-level --type x --type s --no-group --whole-name --at-root --minimal
                $"/bin/($cmd_name)"
              )

              if ($pkgs | is-empty) {
                null
              } else {
                $pkgs | split row "\n"
                | each {|pkg| $"  nixpkgs#($pkg)\n"}
                | prepend $"($cmd_name) is provided by:\n"
                | append "\n" | str join
              }
            }
          )
        }'';
      };
    };

    extraConfig = ''
      use std/dirs

      def --wrapped nixpkgs-review [
        cmd: string,
        --run: string = ${nu},
        --systems: string = "linux",
        ...args: string
      ] {
        cd ~/dev/nixpkgs
        ^nixpkgs-review $cmd --run $run --systems $systems ...$args
      }

      def --wrapped "nix build" [
        --log-format: string = "multiline-with-logs",
        ...args: string
      ] {
        ^nix build --log-format $log_format ...$args
      }

      # View package in nixpkgs
      def np [
        pkg: string  # package name
      ] {
        EDITOR=`${bat}` nix edit --file ~/dev/nixpkgs $pkg
      }

      tabs -4
    '';

    extraLogin = let
      source = pkgs.writeText "env.sh"
      (lib.optionals (osConfig ? system.build.setEnvironment) [
        osConfig.system.build.setEnvironment
      ] ++ [
        (config.home.sessionVariablesPackage + /etc/profile.d/hm-session-vars.sh)
      ] |> map (src: "source ${lib.escapeShellArg src}")
        |> lib.concatLines);
    in ''
      ${lib.getExe pkgs.bash-env-json} ${lib.escapeShellArg source}
        | from json
        | get env
        | transpose name value
        | where name !~ '^__'
        | transpose --header-row --as-record
        | load-env
    '';
  };

  services.ssh-agent.enable = true;

  systemd.user.sessionVariables = {
    inherit (config.home.sessionVariables)
      SECRET_BACKEND TMPDIR XDG_CACHE_HOME XDG_STATE_HOME;
  };

  systemd.user.tmpfiles.rules = [
    "d %C 700 - - 90d"
    "d %S 700 - - 270d"
    "d %t/ssh 700"
    "d %t/tmp 700 - - 24h"
  ];

  xdg.configFile."ov/config.yaml".text = builtins.toJSON {
    DisableMouse = true;
    General = {
      TabWidth = 4;
    };
  };

  xdg.userDirs =
  let
    home = config.home.homeDirectory;
  in {
    enable = true;
    desktop = "${home}/tmp";
    documents = "${home}/var";
    download = "${home}/tmp";
    pictures = "${home}/img";
    music = "${home}/msc";
    publicShare = null;
    templates = null;
    videos = null;
  };
}
