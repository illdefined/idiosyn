{ self, nixos-hardware, ... }: { lib, config, pkgs, ... }: {
  imports = with self.nixosModules; [
    default
    mimalloc
    physical
    graphical
    wireless
  ];
  
  boot = {
    binfmt = {
      emulatedSystems = [ "aarch64-linux" "x86_64-linux" ];
      preferStaticEmulators = true;
    };
  };

  nixpkgs = {
    hostPlatform = {
      system = "riscv64-linux";
      config = "riscv64-unknown-linux-musl";
      gcc.arch = "rv64imafdc";
      useLLVM = true;
      linker = "lld";
    };
  };
}
