{ mpv-rtkit, ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  programs.mpv = {
    enable = true;
    defaultProfiles = [ "high-quality" ];
    config = {
      #access-references = false;

      # Video output
      vo = "gpu-next";
      gpu-api = "vulkan";
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

      vrr = {
        profile-cond = "fullscreen";
        video-sync = "audio";
      };
    };

    scripts = with pkgs.mpvScripts; [
      mpv-rtkit.packages.${pkgs.system}.default
      mpris
      autocrop
      autodeint
    ];

    scriptOpts = {
      autocrop.auto = false;
    };
  };
}
