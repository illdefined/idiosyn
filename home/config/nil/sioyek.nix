{ ... }: { config, lib, ... }@args:
let
  osConfig = args.osConfig or { };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
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

  xdg.mimeApps.defaultApplications = {
    "application/pdf" = [ "sioyek.desktop" ];
  };
}
