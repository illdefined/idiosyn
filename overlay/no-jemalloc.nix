{ nixpkgs, ... }: final: prev:

let
  inherit (nixpkgs.lib.attrsets) genAttrs;
in genAttrs [
  "firefox-unwrapped"
] (pkg: prev.${pkg}.override { jemallocSupport = false; })
// {
  firefox = final.wrapFirefox final.firefox-unwrapped { };
}
