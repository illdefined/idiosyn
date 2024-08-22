{ ... }: { lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation (finalAttrs: {
  pname = "libslz";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "wtarreau";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    hash = "sha256-+3e0yTk6l8miQs/zBYSiPuj/gRWICR3QYTkV3OAHAtI=";
  };

  makeFlags = [
    "TOPDIR=$(src)"
    "PREFIX=$(out)"
  ];

  buildFlags = [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    "CC=cc"
  ];

  meta = {
    homepage = "http://www.libslz.org/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ mvs ];
    platforms = lib.platforms.all;
  };
})
