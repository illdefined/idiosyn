{ nixpkgs, ... }:

let inherit (nixpkgs) lib;
in lib.mapAttrs (system: platform: lib.systems.elaborate platform) {
  "x86_64-linux" = {
    system = "x86_64-linux";
    config = "x86_64-unknown-linux-musl";
  };

  "aarch64-linux" = {
    system = "aarch64-linux";
    config = "aarch64-unknown-linux-musl";
  };

  "riscv64-linux" = {
    system = "riscv64-linux";
    config = "riscv64-unknown-linux-musl";
  };
}
