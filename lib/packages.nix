{ nixpkgs, ... }:

let
  inherit (builtins) any filter;
  inherit (nixpkgs.lib.strings) getName;
in {
  remove = nameList: pkgList:
    filter (pkg: !any (elem: getName pkg == elem) nameList) pkgList;
}
