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
        BusName = "org.freedesktop.Secret";
        ExecStart = "${pkgs.oo7-server}/libexec/oo7-daemon";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
