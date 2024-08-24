{ nixpkgs, ... }:

let
  inherit (builtins) filter isList isString stringLength;
  inherit (nixpkgs.lib.lists) subtractLists;
  inherit (nixpkgs.lib.strings) addContextFrom;

  split = strOrList:
    if isList strOrList then strOrList
    else builtins.split "[[:space:]]+" strOrList
      |> filter (flag: isString flag && stringLength flag > 0)
      |> map (flag: addContextFrom strOrList flag);

  remerge = strOrList: list:
    if isList strOrList then list
    else toString list;
in {
  remove = rem: strOrList: split strOrList
    |> subtractLists rem
    |> remerge strOrList;

  subst = sub: strOrList: split strOrList
    |> map (flag: sub.${flag} or flag)
    |> remerge strOrList;
}
