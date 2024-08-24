{ nixpkgs, ... }:

let
  inherit (builtins) elem filter;
  inherit (nixpkgs.lib.strings) getName;
in {
  remove = nameList: pkgList:
    filter (pkg: !elem (getName pkg) nameList) pkgList;
}
