{ self, ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };

  inherit (pkgs.stdenv) hostPlatform;

  helix = lib.getExe config.programs.helix.package;
  mpv = lib.getExe config.programs.mpv.package;
  xdg-open = lib.getExe' pkgs.xdg-utils "xdg-open";
in {
  programs.yazi = {
    enable = true;
    plugins = with self.packages.${hostPlatform.system}; {
      inherit (pkgs.yaziPlugins)
        git
        mediainfo;

      hexyl = yazi-hexyl;
      mdcat = yazi-mdcat;
      office = lib.mkIf osConfig.hardware.graphics.enable or false
        yazi-office;
    };

    initLua = ''
      require("git"):setup({
        show_branch = true
      })
    '';

    settings = {
      sort_by = "mtime";
      show_symlink = true;
      tab_size = 4;
      cache_dir = "${config.xdg.cacheHome}/yazi";
      image_filter = "lanczos3";

      keymap = {
        manager.prepend_keymap = [
          { on = "t"; run = "arrow -1"; }
          { on = "n"; run = "arrow 1"; }
          { on = ";"; run = "find_arrow"; }
          { on = ":"; run = "find_arrow --previous"; }
        ];
      };

      opener = {
        play = lib.mkIf (osConfig.hardware.graphics.enable or false) [
          {
            run = ''${mpv} "$@"'';
            orphan = true;
          }
        ];

        edit = [
          {
            run = ''${helix} "$@"'';
            block = true;
          }
        ];

        open = [
          {
            run = ''${xdg-open} "$@"'';
            desc = "Open";
          }
        ];
      };

      plugin = {
        append_fetchers = [
          { id = "git"; name = "*"; run = "git"; prio = "normal"; }
        	{ id = "git"; name = "*/"; run = "git"; prio = "normal"; }
        ];

        prepend_preloaders = map (mime: { inherit mime; run = "office"; }) [
          "application/openxmlformats-officedocument.*"
          "application/oasis.opendocument.*"
          "application/ms-*"
          "application/msword"
        ];

        prepend_previewers = [
          { mime = "text/markdown"; run = "mdcat"; }
        ] ++ map (mime: { inherit mime; run = "office"; }) [
          "application/openxmlformats-officedocument.*"
          "application/oasis.opendocument.*"
          "application/ms-*"
          "application/msword"
        ] ++ map (mime: { inherit mime; run = "ouch"; }) [
          "application/*zip"
          "application/x-tar"
          "application/x-bzip2"
          "application/x-7z-compressed"
          "application/x-rar"
          "application/x-xz"
          "application/x-zstd"
        ];

        append_previewers = [
          { mime = "*"; run = "hexyl"; }
        ];
      };

      open = {
        rules = [
          { mime = "{audio,video}/*"; use = "play"; }
          { mime = "text/*"; use = "edit"; }
          { mime = "text/html"; use = "open"; }
        ];
      };
    };
  };
}
