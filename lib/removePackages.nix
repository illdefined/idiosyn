{ nixpkgs, ... }:

let
  inherit (builtins) elem filter;
  inherit (nixpkgs.lib.strings) getName;
in pkgOrNameList: pkgList:
  let nameList = map (pkg: getName pkg) pkgOrNameList;
  in filter (pkg: !elem (getName pkg) nameList) pkgList
