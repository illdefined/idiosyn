{ self, nur, stylix, nix-index-database, niri, ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };
in {
  imports = [
    nur.hmModules.nur
    self.homeModules.locale-en_EU
    nix-index-database.hmModules.nix-index
    stylix.homeManagerModules.stylix

    niri.homeModules.config
    niri.homeModules.stylix
  ] ++ self.lib.mods [
    ./firefox.nix
    ./wayland.nix
  ];

  home.stateVersion = "24.11";
  home.enableNixpkgsReleaseCheck = false;

  home.activation = {
    fish = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${lib.getExe config.programs.fish.package} -c 'set -U fish_greeting'
    '';
  };

  home.packages = with pkgs; [
    # Terminfo
    kitty.terminfo

    # Core utilities
    (lib.meta.setPrio 0 uutils-coreutils-noprefix)

    # Text manipulation
    #delta
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
  ];

  home.sessionVariables = {
    TMPDIR = "$XDG_RUNTIME_DIR/tmp";
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

  home.shellAliases = {
    icat = "kitten icat";
  };

  home.preferXdgDirectories = true;

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
      color = "gruvbox";
      mem_as_value = true;
      network_use_binary_prefix = true;
      network_use_bytes = true;
    };
  };

  programs.eza = {
    enable = true;
    icons = true;
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

  programs.fish = {
    enable = true;
    functions = {
      fish_prompt = ''
        set -l user_colour 'green'
        if fish_is_root_user
          set user_colour 'red'
        end

        echo -n -s (set_color $user_colour --bold) $USER@ (prompt_hostname) \
          (set_color blue --bold) ' ' (prompt_pwd) ' ❯ ' (set_color normal)
      '';

      fish_right_prompt = ''
        set -l st $status

        if test $st -ne 0
          set_color red --bold
          printf "%s " (sysexit $st)
          set_color normal
        end
      '';

      fish_title = "prompt_pwd";

      sysexit = builtins.readFile ./sysexit.fish;
    };

    interactiveShellInit = ''
      if type -q tabs
        tabs -4
      end
    '';
  };

  programs.git = let
    key = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAICczPHRwY9MAwDGlcB0QgMOJjcpLJhVU3covrW9RBS62AAAABHNzaDo=";
  in {
    enable = true;
    #delta.enable = true;

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

  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      editor.auto-pairs = {
        "“" = "”";
        "‘" = "’";
        "„" = "“";
        "‚" = "‘";
      };

      editor.whitespace.render = {
        nbsp = "all";
        nnbsp = "all";
        tab = "all";
      };

      editor.whitespace.characters = {
        nbsp = "␣";
        nnbsp = "⍽";
        tab = "»";
        tabpad = "·";
      };

      keys.normal = {
        minus = "command_mode";
        r = "move_char_left";
        n = "move_visual_line_down";
        t = "move_visual_line_up";
        h = "move_char_right";
      };
    };
  };

  programs.jq.enable = true;
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

  programs.vim = {
    enable = true;
    settings = {
      background = "dark";
      expandtab = false;
      number = true;
      shiftwidth = 4;
      tabstop = 4;
    };
    extraConfig = ''
      " no Vi compatibility
      set nocompatible

      " Unicode support
      set encoding=utf-8

      " special characters
      set list
      set listchars=tab:»·,trail:·,extends:…

      set ruler

      " movement
      noremap r h
      noremap R H
      noremap n j
      noremap t k
      noremap h l
      noremap H L

      " beginning of previous word
      noremap p b

      " end of word
      noremap l e
      noremap L E

      " change one char
      noremap X s

      " repeat search
      noremap ; n
      noremap : N

      " paste
      noremap s p
      noremap S P

      " join lines
      noremap N J

      " change
      noremap e c
      noremap E C

      " replace
      noremap z r
      noremap Z R

      " inclusive jump
      noremap m f
      noremap M F

      " exlusive jump
      noremap f t
      noremap F T

      " command mode
      noremap - :
    '';
  };

  services.ssh-agent.enable = true;

  systemd.user.tmpfiles.rules = [
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
