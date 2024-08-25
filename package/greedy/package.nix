{ ... }: { stdenvNoCC, lib }:

stdenvNoCC.mkDerivation {
  name = "greedy";

  buildCommand = ''
    cp ${./greedy.xkb} "$out"
  '';

  passthru = {
    xkbOptions = [
      "ctrl:nocaps"
      "altwin:alt_super_win"
      "level3:ralt_switch"
      "level5:rtctl_switch"
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
