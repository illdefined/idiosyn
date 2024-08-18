{ ... }: { lib, config, ... }: {
  boot.loader.systemd-boot.editor = false;

  security.acme.acceptTerms = true;
  security.pam.services.swaylock.fprintAuth = false;
  security.pam.services.login.fprintAuth = false;
  security.pam.services.sudo-rs = {
    fprintAuth = config.services.fprintd.enable;
    sshAgentAuth = config.security.pam.sshAgentAuth.enable;
  };

  security.sudo.enable = false;
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = config.security.pam.services.sudo-rs.fprintAuth
      || config.security.pam.services.sudo-rs.sshAgentAuth;
  };

  services.logind.killUserProcesses = true;
}
