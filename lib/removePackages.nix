{ nixpkgs, ... }:

let
  inherit (builtins) match filter foldl';
  inherit (nixpkgs.lib.strings) getName;

  fold = name: acc: regex:
    if acc == false then false
    else match regex name == null;
in regexList: filter (pkg: pkg != null -> foldl' (getName pkg |> fold) true regexList)
