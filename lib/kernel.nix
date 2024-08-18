{ nixpkgs, ... }:
let
  inherit (builtins)
    isAttrs
    isInt
    length
    match
    toString;

  inherit (nixpkgs.lib.asserts)
    assertMsg;

  inherit (nixpkgs.lib.attrsets)
    isDerivation
    mapAttrsToList
    mergeAttrsList;

  inherit (nixpkgs.lib.lists)
    flatten;

  inherit (nixpkgs.lib.strings)
    concatStrings
    concatStringsSep
    escape;

  isKey = str: match "[0-9A-Z][0-9A-Zx_]*" str != null;
  isNum = str: match "(0x[0-9A-Fa-f]+|[1-9][0-9]*)" str != null;

  mkValueString = v: let
    v' = toString v;
  in if v == true then "y"
    else if isInt v || isNum v' then v'
    else "\"${escape [ "\"" ] v'}\"";

in rec {
  flattenAttrs = let
    compose = p: n: if isKey n then p ++ [ n ] else p;
    recurse = p: v:
      if isValue v then { ${concatStringsSep "_" p} = v; }
      else mapAttrsToList (n: v: recurse (compose p n) v) v;
  in attrs: recurse [ ] attrs |> flatten |> mergeAttrsList;

  option = v: { _option = v; };
  isValue = x: isAttrs x -> !isDerivation x -> x ? _option;
  isOptional = x: isAttrs x && !isDerivation x && x ? _option;
  getValue = x: if isOptional x then x._option else x;

  mkKey = n: assert isKey n; "CONFIG_${n}";

  mkKeyValue = n: v: let
    v' = getValue v;
  in if (v' == false || v' == null)
    then "# ${mkKey n} is not set"
    else "${mkKey n}=${mkValueString v'}";

  mkConfig = attrs: mapAttrsToList (k: v: mkKeyValue k v + "\n") attrs
    |> concatStrings;
}
