{ self, nixpkgs, ... }: final: prev: 
let
  inherit (nixpkgs) lib;
  inherit (lib) toList;
  inherit (prev.stdenv) buildPlatform hostPlatform;
  inherit (self.lib) removePackages;
in {
  bind = prev.bind.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs or [ ]
      |> removePackages [ "jemalloc" ];
  });

  keyutils = prev.keyutils.overrideAttrs (prevAttrs: {
    NIX_LDFLAGS = toList prevAttrs.NIX_LDFLAGS or [ ] ++ [ "--undefined-version" ];
  });

  kexec-tools = prev.kexec-tools.override { stdenv = final.gccStdenv; };

  llvmPackages = prev.llvmPackages // {
    libcxx = prev.llvmPackages.libcxx.override {
      devExtraCmakeFlags = [ "-DLIBCXX_HAS_MUSL_LIBC=1" ];
    };
  };

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
    postFixup = prevAttrs.postFixup + ''
      cat <<EOF >>"$out/nix-support/setup-hook"
      setuptoolsDistutilsHook() {
        export SETUPTOOLS_USE_DISTUTILS="stdlib"
      }

      addEnvHooks "\$hostOffset" setuptoolsDistutilsHook
      EOF
    '';
  })).override {
    enableLTO = false;
    packageOverrides = final: prev: {
      html5-parser = prev.html5-parser.overrideAttrs (prevAttrs: {
        env = prevAttrs.env or { } // {
          LD = "${final.buildPackages.stdenv.cc.targetPrefix}ld";
        };
      });
    };
  };

  python3Packages = final.python3.pkgs;

  redis = prev.redis.overrideAttrs {
    doCheck = false;
  };

  sioyek = prev.sioyek.overrideAttrs (prevAttrs: {
    env = prevAttrs.env or { } // {
      NIX_CFLAGS_COMPILE = toList prevAttrs.env.NIX_CFLAGS_COMPILE or [ ]
        ++ [ "-DGL_CLAMP=GL_CLAMP_TO_EDGE" ] |> toString;
    };
  });

  time = prev.time.overrideAttrs (prevAttrs: {
    env = prevAttrs.env or { } // {
      CFLAGS = toList prevAttrs.env.CFLAGS or [ ] ++ [
        "-Wno-error=implicit-function-declaration"
      ] |> toString;
    };
  });

  zeromq = prev.zeromq.overrideAttrs (prevAttrs: {
    postPatch = prevAttrs.postPatch or "" + ''
      substituteInPlace CMakeLists.txt \
        --replace-fail 'CACHELINE_SIZE EQUAL "undefined"' 'CACHELINE_SIZE STREQUAL "undefined"'
    '';
  });

  zlib = prev.zlib.override {
    splitStaticOutput = false;
  };
}
