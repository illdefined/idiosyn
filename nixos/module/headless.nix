{ self, ... }: { config, lib, pkgs, ... }: {
  imports = with self.nixosModules; [
    mimalloc
  ];

  boot.kernelParams = [ "panic=-1" ];

  boot.initrd.network = {
    enable = false;
    ssh.enable = true;
    ssh.authorizedKeys = lib.flatten (lib.mapAttrsToList (_: user: user.openssh.authorizedKeys.keys) (lib.filterAttrs (_: user: lib.any (group: group == "wheel") user.extraGroups) config.users.users));
  };

  hardware.graphics.enable = false;

  security.lockKernelModules = lib.mkIf (config.boot.kernelPackages.kernel.config.isEnabled "MODULES") true;
  security.protectKernelImage = true;
  services.openssh.enable = true;
  services.openssh.openFirewall = true;

  systemd.network.networks."97-ethernet-default-dhcp-static.network" = {
    matchConfig.Type = "ether";
    matchConfig.Name = "en*";

    networkConfig.DHCP = "yes";
    dhcpV4Config.UseDNS = false;
    dhcpV6Config.UseDNS = false;
    ipv6AcceptRAConfig.Token = lib.mkDefault "static:::1";
  };
}
