{ self, ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  programs.retroarch = {
    enable = true;
    cores = lib.genAttrs [
      "bsnes-hd"
      "swanstation"
      "mupen64plus"
    ] (_: { enable = true; });

    settings = {
      # menu
      menu_driver = "ozone";
      menu_show_online_updater = "false";
      menu_show_core_updater = "false";
      menu_timedate_style = "11";

      # input
      input_driver = "wayland";
      input_joypad_driver = "sdl2";  # "udev"
      enable_device_vibration = "true";
      pause_on_disconnect = "true";

      # video
      video_driver = "vulkan";
      video_windowed_fullscreen = "true";
      video_vsync = "true";

      # audio
      audio_driver = "pipewire";
      audio_enable_menu = "false";
      audio_sync = "true";
      microphone_driver = "pipewire";

      # camera
      camera_driver = "pipewire";
    };
  };
}
