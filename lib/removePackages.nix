{ nixpkgs, ... }:

let
  inherit (builtins) match filter foldl';
  inherit (nixpkgs.lib.strings) getName;

  fold = name: acc: regex:
    if acc == false then false
    else match regex name == null;
in regexList: filter (pkg: foldl' (getName pkg |> fold) true regexList)
