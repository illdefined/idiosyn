{ ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  systemd.user.services = {
    oo7-server = {
      Unit = {
        Description = "oo7 Secret service";
      };

      Service = {
        BusName = "org.freedesktop.secrets";
        ExecStart = "${pkgs.oo7-server}/libexec/oo7-daemon";
        Restart = "on-failure";
      };

      Install = {
        Alias = "org.freedesktop.secrets.service";
      };
    };

    oo7-portal = {
      Unit = {
        Description = "oo7 Secret portal service";
        PartOf = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        BusName = "org.freedesktop.impl.portal.desktop.oo7";
        ExecStart = "${pkgs.oo7-portal}/libexec/oo7-portal";
      };

      Install = {
        Alias = "org.freedesktop.impl.portal.desktop.oo7.service";
      };
    };
  };

  xdg.dataFile = {
    "dbus-1/services/org.freedesktop.secrets.service".text = ''
      [D-BUS Service]
      Name=org.freedesktop.secrets
      SystemdService=oo7-server.service
    '';

    "dbus-1/services/org.freedesktop.impl.portal.desktop.oo7.service".text = ''
      [D-BUS Service]
      Name=org.freedesktop.impl.portal.desktop.oo7
      SystemdService=oo7-portal.service
    '';
  };

  xdg.portal.configPackages = with pkgs; [ oo7-portal ];
}
