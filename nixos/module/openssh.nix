{ ... }: { lib, ...}:

let
  ciphers = [
    "chacha20-poly1305@openssh.com"
    "aes256-gcm@openssh.com"
    "aes128-gcm@openssh.com"
  ];

  sigAlgorithms = [
    "ssh-ed25519-cert-v01@openssh.com"
    "ssh-ed25519"
    "sk-ssh-ed25519-cert-v01@openssh.com"
    "sk-ssh-ed25519@openssh.com"
  ];

  kexAlgorithms = [
    "sntrup761x25519-sha512@openssh.com"
    "curve25519-sha256"
    "curve25519-sha256@libssh.org"
  ];

  macs = [
    "umac-128-etm@openssh.com"
    "hmac-sha2-512-etm@openssh.com"
    "hmac-sha2-256-etm@openssh.com"
  ];
in {
  programs.ssh = {
    inherit ciphers kexAlgorithms macs;
    hostKeyAlgorithms = sigAlgorithms;
    pubkeyAcceptedKeyTypes = sigAlgorithms;
    setXAuthLocation = false;
  };

  services.openssh = {
    authorizedKeysInHomedir = false;
    hostKeys = lib.mkDefault [
      {
        path = "/etc/keys/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    settings = {
      PermitRootLogin = "no";

      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AuthenticationMethods = "publickey";

      Ciphers = ciphers;
      Macs = macs;

      KexAlgorithms = kexAlgorithms;
      HostKeyAlgorithms = lib.concatStringsSep "," sigAlgorithms;
      PubkeyAcceptedAlgorithms = lib.concatStringsSep "," sigAlgorithms;

      # Remove stale Unix sockets when forwarding
      StreamLocalBindUnlink = true;

      ClientAliveInterval = 900;
    };
  };
}
