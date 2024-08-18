{ ... }: { lib, ... }: {
  services.postfix.config = lib.mkDefault {
    smtpd_tls_security_level = "may";
  };
}
