{ nixpkgs, ... }:

let
  inherit (builtins)
    isFunction
    filter isList
    match isString stringLength
    unsafeDiscardStringContext;

  inherit (nixpkgs.lib.attrsets) foldlAttrs;
  inherit (nixpkgs.lib.lists) flatten subtractLists;
  inherit (nixpkgs.lib.strings) addContextFrom;

  split = strOrList:
    if isList strOrList then flatten strOrList
    else builtins.split "[[:space:]]+" strOrList
      |> filter (flag: isString flag && stringLength flag > 0);

  merge = strOrList: list:
    if isList strOrList then list
    else toString list |> addContextFrom strOrList;
in substAttrs: strOrList: split strOrList
  |> map (flag: let subst = foldlAttrs (result: regex: subst:
      if result != false then result
      else let groups = match regex flag;
        in if groups == null then false
        else if isFunction subst then subst groups
        else subst)
      false substAttrs;
    in if subst != false then subst else flag)
  |> filter (flag: flag != null)
  |> merge strOrList
