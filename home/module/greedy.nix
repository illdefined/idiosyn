{ self, ... }: { config, lib, pkgs, ... }:
let
  inherit (self.packages.${pkgs.system}) greedy;
in {
  home.file.".xkb/symbols/greedy".source = greedy;
  home.keyboard = {
    layout = "greedy" |> lib.mkDefault;
    options = greedy.xkbOptions |> lib.mkDefault;
  };
}
