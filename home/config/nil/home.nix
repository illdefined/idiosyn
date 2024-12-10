{ self, nur, catppuccin, nix-index-database, niri, ripgrep-all, ... }:
{ config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };

  bat = lib.getExe config.programs.bat.package;
  col = lib.getExe' pkgs.util-linux "col";
  nix-locate = lib.getExe' config.programs.nix-index.package "nix-locate";
  sh = lib.getExe self.packages.${pkgs.system}.hush;
in {
  imports = [
    nur.modules.homeManager.default
    self.homeModules.greedy
    self.homeModules.locale-en_EU
    catppuccin.homeManagerModules.catppuccin
    niri.homeModules.config
  ] ++ self.lib.mods [
    ./gammarelay.nix
    ./founts.nix
    ./editor.nix
    ./desktop.nix
    ./bar.nix
    ./terminal.nix
    ./firefox.nix
    ./thunderbird.nix
    ./sioyek.nix
    ./texlive.nix
    ./mpv.nix
    ./music.nix
  ];

  home.stateVersion = "24.11";
  home.enableNixpkgsReleaseCheck = false;

  catppuccin = {
    enable = true;
    pointerCursor.enable = true;
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
    #xcp

    # Development
    pijul

    # Calculator
    fend

    jaq

    ripgrep-all.packages.${system}.default

    # Required for Carapace nix completer
    sqlite
  ];

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

  programs.bat.enable = true;

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

  programs.fd.enable = true;

  programs.git = let
    key = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAICczPHRwY9MAwDGlcB0QgMOJjcpLJhVU3covrW9RBS62AAAABHNzaDo=";
  in {
    enable = true;
    delta.enable = true;

    userName = "Mikael Voss";
    userEmail = "mvs@nyantec.com";

    extraConfig = {
      core = {
        eol = "lf";
        fsync = "committed";
      };

      user.signingKey = "key::${key}";

      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;

      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = toString (pkgs.writeText "allowed-signers" ''
        ${config.programs.git.userEmail} ${key}
      '');
      commit.gpgSign = true;
      tag.gpgSign = true;
    };
  };

  programs.man.generateCaches =
    osConfig.documentation.man.generateCaches or false;
  programs.ripgrep.enable = true;

  programs.ssh = {
    enable = true;
    compression = true;

    controlMaster = "auto";
    controlPath = "\${XDG_RUNTIME_DIR}/ssh/%r@%n:%p";
    controlPersist = "1m";

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

  programs.nushell = {
    enable = true;
    envFile.text = let
      ls-colours = pkgs.runCommand "ls-colours" { } ''
        ${lib.getExe pkgs.vivid} generate catppuccin-mocha >$out
      '' |> builtins.readFile;
    in ''
      load-env {
        CARAPACE_BRIDGES: `bash`
        EDITOR: `${lib.getExe config.programs.helix.package}`
        LS_COLORS: `${ls-colours}`
        MANROFFOPT: `-c`
        MANPAGER: `${sh} -c '${col} -bx | ${bat} -l man -p'`

        PROMPT_COMMAND: {
          let dir = match (do --ignore-shell-errors { $env.PWD | path relative-to $nu.home-path }) {
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
        }

        PROMPT_COMMAND_RIGHT: {
          [
            (ansi light_red)
            ($env.CMD_DURATION_MS | into int | into duration --unit ms)
          ] | str join
        }

        PROMPT_INDICATOR: { "› " }

        TMPDIR: $"($env.XDG_RUNTIME_DIR)/tmp"
      }

      if SSH_AUTH_SOCK not-in $env {
        $env.SSH_AUTH_SOCK = $"($env.XDG_RUNTIME_DIR)/ssh-agent"
      }
    '';

    configFile.text = ''
      $env.config = {
        show_banner: false

        history: {
          max_size: 131072
          sync_on_enter: true
          file_format: "sqlite"
          isolation: true
        }

        use_kitty_protocol: true

        keybindings: [
          {
            name: completion_menu
            modifier: control
            keycode: char_i
            mode: [ emacs vi_normal vi_insert ]
            event: {
              until: [
                { send: menu name: completion_menu }
                { send: menunext }
                { edit: complete }
              ]
            }
          }
        ]

        hooks: {
          command_not_found: {
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
          }
        }
      }

      tabs -4
    '';
  };

  services.pueue = {
    enable = true;
    settings = {
      shared = {
        use_unix_socket = true;
      };

      client = {
        status_time_format = "%H:%M:%S %Z";
        status_datetime_format = "%Y-%m-%d %H:%M:%S %Z";
      };

      daemon = {
        groups.default = 0;
        callback = lib.mkIf (osConfig.hardware.graphics.enable or false)
          ''${lib.getExe pkgs.libnotify} "Task {{ id }} {{ result }}" "Command: {{ command }}\nPath: {{ path }}\nStatus: {{ exit_code }}'';
        callback_log_lines = 4;
      };
    };
  };

  services.ssh-agent.enable = true;

  systemd.user.sessionVariables = {
    TMPDIR = "$XDG_RUNTIME_DIR/tmp";
    XDG_CACHE_HOME = "\${XDG_CACHE_HOME:-$HOME/.cache}";
  };

  systemd.user.tmpfiles.rules = [
    "d %C 700 - - 90d"
    "d %t/ssh 700"
    "d %t/tmp 700 - - 24h"
  ];

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
