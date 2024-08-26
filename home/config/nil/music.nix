{ ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };

  systemctl = osConfig.systemd.package + /bin/systemctl;
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
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
          command = "${systemctl} --user start mopidy-scan.service";
        }
      ];
    };
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
}
