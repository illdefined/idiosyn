{ self, nixpkgs, ... }: final: prev: 
let
  inherit (nixpkgs) lib;
  inherit (lib) toList;
  inherit (prev.stdenv) buildPlatform hostPlatform;
  inherit (self.lib) removePackages;

  prev' = prev;
  final' = final;
in {
  gst_all_1 = prev.gst_all_1 // {
    gst-plugins-bad = prev.gst_all_1.gst-plugins-bad.overrideAttrs (prevAttrs: {
      buildInputs = prevAttrs.buildInputs or [ ] |> removePackages [ "libajantv2" ];
    });
  };

  perlPackages = prev.perlPackages.overrideScope (final: prev: {
    DBI = prev.DBI.overrideAttrs (prevAttrs: {
      nativeBuildInputs = prevAttrs.nativeBuildInputs or [ ] ++ [
        final'.stdenv.cc
        final'.stdenv.cc.binutils
      ];

      makeMakerFlags = prevAttrs.makeMakerFlags or [ ] ++ [
        "CC=${final'.stdenv.cc.targetPrefix}cc"
        "LD=${final'.stdenv.cc.targetPrefix}cc"
        "CCFLAGS=-Doff64_t=off_t"
      ];
    });
  });

  bind = prev.bind.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ] |> removePackages [ "jemalloc" ];
  });

  diffutils = prev.diffutils.overrideAttrs (prevAttrs: {
    configureFlags = prevAttrs.configureFlags or [ ] ++ [ "--disable-nls" ];

    postPatch = ''
      sed -E -i 's/test-getopt-(gnu|posix)//g' gnulib-tests/Makefile.in
    '';
  });

  gnu-efi = prev.gnu-efi.overrideAttrs (prevAttrs: {
    nativeBuildInputs = prevAttrs.nativeBuildInputs or [ ] ++ [ final.buildPackages.binutils ]; 
    makeFlags = prevAttrs.makeFlags or [ ] ++ [ "CC=${final.stdenv.cc.targetPrefix}cc" ];
  });

  gsm = prev.gsm.overrideAttrs (prevAttrs: {
    makeFlags = prevAttrs.makeFlags or [ ] ++ [ "CC=${final.stdenv.cc.targetPrefix}cc" ];
  });

  keyutils = prev.keyutils.overrideAttrs (prevAttrs: {
    NIX_LDFLAGS = toList prevAttrs.NIX_LDFLAGS or [ ] ++ [ "--undefined-version" ];
  });

  kexec-tools = prev.kexec-tools.override { stdenv = final.gccStdenv; };

  level-zero = prev.level-zero.overrideAttrs (prevAttrs: {
    cmakeFlags = prevAttrs.cmakeFlags or [ ] ++ [ "-DCMAKE_CXX_FLAGS=-Wno-error=deprecated" ];
  });

  libcdio = prev.libcdio.overrideAttrs (prevAttrs: {
    nativeBuildInputs = prevAttrs.nativeBuildInputs or [ ] ++ [ final.buildPackages.binutils ];
  });

  libjpeg = prev.libjpeg.overrideAttrs (prevAttrs: {
    cmakeFlags = prevAttrs.cmakeFlags or [ ] ++ [ "-DFLOATTEST12=fp-contract" ];
  });

  liboping = prev.liboping.overrideAttrs (prevAttrs: {
    configureFlags = prevAttrs.configureFlags or [ ] ++ [
      "ac_cv_func_malloc_0_nonnull=yes"
      "ac_cv_func_realloc_0_nonnull=yes"
    ];
  });

  libselinux = prev.libselinux.override { enablePython = false; };

  liburing = prev.liburing.overrideAttrs (finalAttrs: prevAttrs: {
    version = "2.8";

    src = final.fetchFromGitHub {
      owner = "axboe";
      repo = "liburing";
      rev = "refs/tags/liburing-${finalAttrs.version}";
      hash = "sha256-10zmoMDzO41oNRVXE/6FzDGPVRVJTJTARVUmc1b7f+o=";
    };
  });

  llvmPackages = prev.llvmPackages // {
    libcxx = prev.llvmPackages.libcxx.override {
      devExtraCmakeFlags = [ "-DLIBCXX_HAS_MUSL_LIBC=1" ];
    };
  };

  lua = prev.lua.overrideAttrs (prevAttrs: {
    env = prevAttrs.env or { } // { LD = "${final.stdenv.cc.targetPrefix}ld"; };
    makeFlags = prevAttrs.makeFlags or [ ] ++ [ "LD=${final.stdenv.cc.targetPrefix}ld" ];
  });

  netbsd = prev.netbsd.overrideScope (final: prev: {
    compatIfNeeded = [ final.compat ];

    compat = prev.compat.overrideAttrs (prevAttrs: {
      makeFlags = prevAttrs.makeFlags ++ [ "OBJCOPY=:" ];
    });
  });

  numactl = prev.numactl.overrideAttrs (prevAttrs: {
    patches = prevAttrs.patches or [ ] ++ [
      (final.fetchpatch {
        url = "https://github.com/numactl/numactl/commit/f9deba0c8404529772468d6dd01389f7dbfa5ba9.patch";
        hash = "sha256-TmWfD99YaSIHA5PSsWHE91GSsdsVgVU+qIow7LOwOGw=";
      })
    ];
  });

  python3 = (prev.python3.overrideAttrs (prevAttrs: {
    env = prevAttrs.env or { } // {
      LD = "${final.stdenv.cc.bintools}/bin/${final.stdenv.cc.targetPrefix}ld";
    };

    configureFlags = prevAttrs.configureFlags or [ ] ++ [
      "LD=${final.stdenv.cc.bintools}/bin/${final.stdenv.cc.targetPrefix}ld"
    ];

    postFixup = prevAttrs.postFixup + ''
      cat <<EOF >>"$out/nix-support/setup-hook"
      setuptoolsDistutilsHook() {
        export SETUPTOOLS_USE_DISTUTILS="stdlib"
      }

      addEnvHooks "\$hostOffset" setuptoolsDistutilsHook
      EOF
    '';
  })).override {
    packageOverrides = final: prev: {
      defusedxml = prev.defusedxml.overrideAttrs {
        doCheck = false;
        doInstallCheck = false;
      };
    
      html5-parser = prev.html5-parser.overrideAttrs (prevAttrs: {
        env = prevAttrs.env or { } // {
          LD = "${final.stdenv.cc.targetPrefix}cc";
        };
      });

      netifaces = prev.netifaces.overrideAttrs (prevAttrs: {
        env = prevAttrs.env or { } // {
          NIX_CFLAGS_COMPILE = toList prevAttrs.env.NIX_CFLAGS_COMPILE or [ ] ++ [
            "-Wno-error=int-conversion"
          ] |> toString;
        };
      });

      pycparser = prev.pycparser.overrideAttrs {
        doCheck = false;
        doInstallCheck = false;
      };
    };
  };

  python3Packages = final.python3.pkgs;

  redis = prev.redis.overrideAttrs { doCheck = false; };

  sane-backends = prev.sane-backends.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ] |> removePackages [ "net-snmp" ];
  });

  sioyek = prev.sioyek.overrideAttrs (prevAttrs: {
    env = prevAttrs.env or { } // {
      NIX_CFLAGS_COMPILE = toList prevAttrs.env.NIX_CFLAGS_COMPILE or [ ]
        ++ [ "-DGL_CLAMP=GL_CLAMP_TO_EDGE" ] |> toString;
    };
  });

  soundtouch = prev.soundtouch.overrideAttrs (prevAttrs: {
    nativeBuildInputs = prevAttrs.nativeBuildInputs or [ ] ++ [ final.binutils ];
  });

  time = prev.time.overrideAttrs (prevAttrs: {
    env = prevAttrs.env or { } // {
      CFLAGS = toList prevAttrs.env.CFLAGS or [ ] ++ [
        "-Wno-error=implicit-function-declaration"
      ] |> toString;
    };
  });

  usrsctp = prev.usrsctp.overrideAttrs (prevAttrs: {
    cmakeFlags = prevAttrs.cmakeFlags or [ ] ++ [ "-Dsctp_werror=0" ];
  });

  zeromq = prev.zeromq.overrideAttrs (prevAttrs: {
    postPatch = prevAttrs.postPatch or "" + ''
      substituteInPlace CMakeLists.txt \
        --replace-fail 'CACHELINE_SIZE EQUAL "undefined"' 'CACHELINE_SIZE STREQUAL "undefined"'
    '';
  });

  zlib = prev.zlib.override { splitStaticOutput = false; };
}
