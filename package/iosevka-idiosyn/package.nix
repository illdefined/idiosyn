{ ... }: { iosevka }:

(iosevka.overrideAttrs {
  enableParallelBuilding = false;
}).override {
  set = "-idiosyn-sans-term";
  privateBuildPlan = import ./iosevka.nix // {
    family = "idiosyn sans term";
    spacing = "term";
  };
}
