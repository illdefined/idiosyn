{ self, ... }: {
  lib,
  stdenv,
  buildPackages,
  llvmPackages_19,
  hostPlatform,
  fetchFromGitHub,
  buildEnv,
  callPackage,

  linux-firmware,
  sof-firmware,
  wireless-regdb,

  systemd,

  jq,
  python3,
  perl,
  flex,
  bison,
  bc,
  openssl,
  zstd,
  hexdump,

  elfutils,
  kmod,
  ...
}@args:

lib.makeOverridable ({
  llvmPackages ? llvmPackages_19,
  instSetArch ? hostPlatform.gccarch or null,
  extraConfig ? { },
  firmwarePackages ? [
    linux-firmware
    sof-firmware
    wireless-regdb
  ],
  extraFirmware ? [ ],
  ...
}:

let
  inherit (self.lib) kernel;

  inherit (lib.attrsets)
    filterAttrs
    mapAttrsToList
    mergeAttrsList;

  inherit (lib.strings)
    concatStringsSep;

  firmwareEnv = buildEnv {
    name = "linux-firmware";
    pathsToLink = [ "/lib/firmware" ];
    paths = firmwarePackages;
  } + "/lib/firmware";

  config = lib.mergeAttrsList (map kernel.flattenAttrs [
    (import ./config.nix { inherit kernel lib hostPlatform systemd; })
    extraConfig
    {
      EXTRA_FIRMWARE = extraFirmware;
      EXTRA_FIRMWARE_DIR = kernel.option firmwareEnv;
    }
  ]);
in stdenv.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  pname = "linux-hardened";
  version = "6.10.13-hardened1";

  modDirVersion = lib.versions.pad 3 finalAttrs.version;

  src = fetchFromGitHub {
    owner = "anthraxx";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    hash = "sha256-XWrX1jlUv1cwGzCz8Qqaa1mbetvPWY2ivPLyw6Fx54c=";
  };

  depsBuildBuild = [
    jq

    flex
    bison
    bc
    python3
    perl
    openssl
    hexdump

    zstd
  ];

  nativeBuildInputs = [
    elfutils
    kmod
  ];

  makeFlags = [
    "ARCH:=${hostPlatform.linuxArch}"

    "HOSTCC:=${buildPackages.stdenv.cc}/bin/${buildPackages.stdenv.cc.targetPrefix}cc"
    "HOSTCXX:=${buildPackages.stdenv.cc}/bin/${buildPackages.stdenv.cc.targetPrefix}c++"
    "HOSTLD:=${buildPackages.stdenv.cc}/bin/${buildPackages.stdenv.cc.targetPrefix}ld"
    "HOSTAR:=${buildPackages.stdenv.cc}/bin/${buildPackages.stdenv.cc.targetPrefix}ar"

    "CC:=${llvmPackages.clang-unwrapped}/bin/clang"
    "LD:=${llvmPackages.lld}/bin/ld.lld"
    "AR:=${llvmPackages.llvm}/bin/llvm-ar"
    "NM:=${llvmPackages.llvm}/bin/llvm-nm"
    "OBJCOPY:=${llvmPackages.llvm}/bin/llvm-objcopy"
    "OBJDUMP:=${llvmPackages.llvm}/bin/llvm-objdump"
    "READELF:=${llvmPackages.llvm}/bin/llvm-readelf"
    "STRIP:=${llvmPackages.llvm}/bin/llvm-strip"
  ];

  configfile = config |> kernel.mkConfig;

  requiredPresent = config
    |> filterAttrs (n: v: !kernel.isOptional v && kernel.getValue v != false)
    |> mapAttrsToList kernel.mkKeyValue;

  optionalPresent = config
    |> filterAttrs (n: v: kernel.isOptional v && kernel.getValue v != false)
    |> mapAttrsToList kernel.mkKeyValue;

  requiredAbsent = config
    |> filterAttrs (n: v: !kernel.isOptional v && kernel.getValue v == false)
    |> mapAttrsToList (n: v: kernel.mkKey n);

  optionalAbsent = config
    |> filterAttrs (n: v: kernel.isOptional v && kernel.getValue v == false)
    |> mapAttrsToList (n: v: kernel.mkKey n);

  postPatch = ''
    patchShebangs scripts/
  '';

  preConfigure = ''
    mkdir build

    export KBUILD_BUILD_TIMESTAMP="$(date -u -d @$SOURCE_DATE_EPOCH)"
    export KBUILD_OUTPUT="$(pwd)/build"

    makeFlags+=( "-j $NIX_BUILD_CORES" )
  '' + lib.optionalString (hostPlatform ? linux-kernel.target) ''
    export KBUILD_IMAGE=${lib.escapeShellArg hostPlatform.linux-kernel.target}
  '' + lib.optionalString (instSetArch != null) ''
    export KCFLAGS="-march=${lib.escapeShellArg instSetArch}"
  '';

  configurePhase = ''
    runHook preConfigure

    cat >build/.config <<<"$configfile"
    make "''${makeFlags[@]}" olddefconfig

    runHook postConfigure
  '';

  postConfigure = ''
    # Verify configuration
    for keyValue in "''${requiredPresent[@]}"; do
      if ! grep -F -x -q "$keyValue" build/.config; then
        printf 'Required: %s\nActual:   %s\n\n' "$keyValue" \
          "$(grep -E "''${keyValue%%=*}[ =]" build/.config || echo "(absent)")" >&2
        exit 1
      fi
    done

    for key in "''${requiredAbsent[@]}"; do
      if grep -E -q "^$key=" build/.config; then
        printf 'Required: %s unset or absent.\n   Actual:   %s\n\n' "$key" \
          "$(grep -E -q "^key=" build/.config)" >&2
        exit 1
      fi
    done

    for keyValue in "''${optionalPresent[@]}"; do
      if ! grep -F -x -q "$keyValue" build/.config; then
        printf 'Suggested: %s\nActual:    %s\n\n' "$keyValue" \
          "$(grep -E "''${keyValue%%=*}[ =]" build/.config || echo "(absent)")" >&2
      fi
    done

    for key in "''${optionalAbsent[@]}"; do
      if grep -E -q "^$key=" build/.config; then
        printf 'Suggested: %s unset or absent.\nActual:    %s\n\n' "$key" \
          "$(grep -E "^$key=" build/.config)" >&2
      fi
    done
  '';

  preInstall = let
    installkernel = buildPackages.writeShellScriptBin "installkernel" ''
      cp "$2" "$4"
      cp "$3" "$4"
    '';
  in ''
    export HOME=${installkernel}
  '';

  installFlags = [
    "INSTALL_PATH=$(out)"
    "INSTALL_MOD_PATH=$(out)"
  ];

  installTargets = [
    "install"
    "modules_install"
  ];

  postInstall = ''
    depmod -b "$out" ${finalAttrs.modDirVersion}
    touch "$out/lib/modules/${finalAttrs.modDirVersion}/modules.order"
  '';

  passthru = {
    profile = import ./profile.nix { inherit kernel lib hostPlatform; };

    config = with kernel; {
      isYes = option: getValue config.${option} or false == true;
      isNo = option: getValue config.${option} or false == false;
      isModule = option: false;

      isEnabled = option: getValue config.${option} or false == true;
      isDisabled = option: getValue config.${option} or false == false;
    };

    isHardened = true;
    isLibre = false;
    isZen = false;

    features = {
      efiBootStub = true;
    };

    kernelOlder = lib.versionOlder finalAttrs.version;
    kernelAtLeast = lib.versionAtLeast finalAttrs.version;
  };

  meta = {
    homepage = "https://github.com/anthraxx/linux-hardened";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ mvs ];
    platforms = [ "x86_64-linux" "aarch64-linux" "riscv64-linux" ];
  };
})) args
