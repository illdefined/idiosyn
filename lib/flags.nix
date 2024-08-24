{ nixpkgs, ... }:

let
  inherit (builtins)
    filter isList
    isString stringLength
    unsafeDiscardStringContext;

  inherit (nixpkgs.lib.lists) flatten subtractLists;
  inherit (nixpkgs.lib.strings) addContextFrom;

  split = strOrList:
    if isList strOrList then flatten strOrList
    else builtins.split "[[:space:]]+" strOrList
      |> filter (flag: isString flag && stringLength flag > 0);

  remerge = strOrList: list:
    if isList strOrList then list
    else toString list |> addContextFrom strOrList;
in {
  remove = rem: strOrList: split strOrList
    |> subtractLists rem
    |> remerge strOrList;

  subst = sub: strOrList: split strOrList
    |> map (flag: sub.${unsafeDiscardStringContext flag} or flag)
    |> remerge strOrList;
}
