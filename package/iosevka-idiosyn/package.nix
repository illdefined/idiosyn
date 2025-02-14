{ ... }: { iosevka }:

iosevka.override {
  set = "-idiosyn-sans-term";
  privateBuildPlan = import ./iosevka.nix // {
    family = "idiosyn sans term";
    spacing = "term";
  };
}
