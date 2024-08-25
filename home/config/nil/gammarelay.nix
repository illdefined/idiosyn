{ ... }: { config, lib, pkgs, ... }@args:
let
  osConfig = args.osConfig or { };
in lib.mkIf (osConfig.hardware.graphics.enable or false) {
  systemd.user.services = {
    gammarelay = {
      Unit = {
        Description = "Display temperature and brightness control";
      };

      Service = {
        BusName = "rs.wl-gammarelay";
        ExecStart = lib.getExe pkgs.wl-gammarelay-rs;
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
