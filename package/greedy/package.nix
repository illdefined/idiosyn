{ ... }: { stdenvNoCC, lib }:

stdenvNoCC.mkDerivation {
  __contentAddressed = true;
  outputHashMode = "recursive";
  outputHashAlgo = "sha256";

  name = "greedy";

  buildCommand = ''
    cp ${./greedy.xkb} "$out"
  '';

  passthru = {
    xkbOptions = [
      "ctrl:nocaps"
      "altwin:alt_super_win"
      "lv3:ralt_switch"
      "lv5:rtctl_switch"
      "compose:lwin-altgr"
      "compose:102"
      "nbsp:level3n"
      "keypad:future"
    ];
  };

  meta = {
    platforms = lib.platforms.unix;
  };
}
