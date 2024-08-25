{ self, ... }: { config, lib, pkgs, ... }:
let
  inherit (self.packages.${pkgs.system}) greedy;
in {
  services.xserver.xkb = {
    layout = "greedy" |> lib.mkDefault;
    options = greedy.xkbOptions
      |> lib.concatStringsSep ","
      |> lib.mkDefault;

    extraLayouts.greedy = {
      symbolsFiles = greedy;
      description = "Greedy keyboard layout";
      languages = [ "eng" "deu" "fra" "spa" ];
    };
  };
}
