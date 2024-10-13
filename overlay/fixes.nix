{ nixpkgs, ... }: final: prev: 
let
  inherit (nixpkgs) lib;
  inherit (lib) toList;
  inherit (prev.stdenv) buildPlatform hostPlatform;
in {
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
    postInstall = let
      lib = "$out/lib/${prevAttrs.passthru.libPrefix}";
      prefix = "_sysconfigdata__linux_";
      build = "${buildPlatform.parsed.cpu.name}-${buildPlatform.parsed.abi.name}";
      host = "${hostPlatform.parsed.cpu.name}-${hostPlatform.parsed.abi.name}";
    in ''
      if ! [ -e "${lib}/${prefix}${host}.py" ]; then
        test -e "${lib}/${prefix}.py" \
          && cp "${lib}/${prefix}"{,"${host}"}.py

        test -e "${lib}/${prefix}${build}.py" \
          && cp "${lib}/${prefix}"{"${build}","${host}"}.py
      fi
    '' + prevAttrs.postInstall;

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
      packaging = prev.packaging.overrideAttrs (prevAttrs: {
        env = prevAttrs.env or { } // {
          SETUPTOOLS_USE_DISTUTILS = "stdlib";
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

  zlib = prev.zlib.overrideAttrs (prevAttrs: {
    configureFlags = prevAttrs.configureFlags or [ ]
      |> lib.subtractLists [ "--shared" "--static" ];
  });
}
