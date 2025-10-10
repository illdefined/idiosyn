{ ... }: { lib, ... }: {
  services.postfix.settings.main = lib.mkDefault {
    smtpd_tls_security_level = "may";
  };
}
