{ ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  home.packages = [ pkgs.goldwarden ];

  systemd.user.services = {
    goldwarden = {
      Unit = {
        Description = "Goldwaren daemon";
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${lib.getExe pkgs.goldwarden} daemonize";
        Environment = [
          "PATH=${lib.makeBinPath [ pkgs.pinentry-qt ]}"
        ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
