{ self, nixpkgs, lix-module, colmena, rust-overlay, niri, ... }:

final: prev:

nixpkgs.lib.composeManyExtensions [
  lix-module.overlays.default
  colmena.overlays.default
  rust-overlay.overlays.default
  niri.overlays.niri
  self.overlays.no-x
  self.overlays.no-alsa
  self.overlays.no-jemalloc
  self.overlays.modern-minimal
] final prev
