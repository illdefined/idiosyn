{ ... }: { config, lib, ... }: {
  nixpkgs.config = {
    permittedInsecurePackages = [
      "jitsi-meet-1.0.8043"
    ];
  };
}
