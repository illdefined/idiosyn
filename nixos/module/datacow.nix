{ ... }: { config, lib, pkgs, ... }:

let
  cfg = config.services;

  noDataCow = dir: ''
    mkdir -p ${lib.escapeShellArg dir}
    ${pkgs.e2fsprogs}/bin/chattr +C ${lib.escapeShellArg dir}
  '';
in {
  systemd.services.mysql.preStart = lib.mkIf cfg.mysql.enable
    (lib.mkBefore (noDataCow cfg.mysql.dataDir));
  systemd.services.postgresql.preStart = lib.mkIf cfg.postgresql.enable
    (lib.mkBefore (noDataCow cfg.postgresql.dataDir));
}
