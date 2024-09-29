{ nixpkgs, ... }:

let inherit (nixpkgs) lib;
in lib.mapAttrs (system: platform: lib.systems.elaborate platform) {
  "x86_64-linux" = {
    system = "x86_64-linux";
    useLLVM = true;
    linker = "lld";
  };

  "aarch64-linux" = {
    system = "aarch64-linux";
    useLLVM = true;
    linker = "lld";
  };

  "riscv64-linux" = {
    system = "riscv64-linux";
    useLLVM = true;
    linker = "lld";
  };
}
