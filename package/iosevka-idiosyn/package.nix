{ ... }: { iosevka }:

(iosevka.overrideAttrs {
  __contentAddressed = true;
  outputHashMode = "recursive";
  outputHashAlgo = "sha256";

  enableParallelBuilding = false;
}).override {
  set = "-idiosyn-sans-term";
  privateBuildPlan = import ./iosevka.nix // {
    family = "idiosyn sans term";
    spacing = "term";
  };
}
