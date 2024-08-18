{ self, nixpkgs, lix-module, colmena, rust-overlay, ... }:

final: prev:

nixpkgs.lib.composeManyExtensions [
  lix-module.overlays.default
  colmena.overlays.default
  rust-overlay.overlays.default
#  self.overlays.no-x
#  self.overlays.no-alsa
#  self.overlays.no-jemalloc
#  self.overlays.modern-minimal
] final prev
