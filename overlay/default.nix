{ self, nixpkgs, lix-module, colmena, rust-overlay, niri, ... }:

final: prev:

nixpkgs.lib.composeManyExtensions [
  lix-module.overlays.default
  colmena.overlays.default
  rust-overlay.overlays.default
  niri.overlays.niri
  self.overlays.mimalloc
  self.overlays.modern-minimal
  self.overlays.riscv
  self.overlays.aarch
] final prev
