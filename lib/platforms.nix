{ nixpkgs, ... }:

let inherit (nixpkgs) lib;
in lib.mapAttrs (system: platform: lib.systems.elaborate platform) {
  "x86_64-linux" = {
    system = "x86_64-linux";
    config = "x86_64-unknown-linux-musl";
    useLLVM = true;
    linker = "lld";
    gcc.arch = "x86-64-v3";
  };

  "aarch64-linux" = {
    system = "aarch64-linux";
    config = "aarch64-unknown-linux-musl";
    useLLVM = true;
    linker = "lld";
    gcc.arch = "armv8-a";
  };

  "riscv64-linux" = {
    system = "riscv64-linux";
    config = "riscv64-unknown-linux-gnu";
    useLLVM = true;
    linker = "lld";
    gcc.arch = "rv64imacfd";
  };
}
