{ fenix
, config
, system
, pkgs
, lib
, crane
, enhanceCrane
, mergeArgs
, universalLlvmConfig
, targetLlvmConfigWrapper
, nixpkgs
}:
let
  defaultChannel = fenix.packages.${system}.${config.toolchain.channel.default};

  # mold wrapper from https://discourse.nixos.org/t/using-mold-as-linker-prevents-libraries-from-being-found/18530/5
  mold-wrapped =
    let
      bintools-wrapper = "${nixpkgs}/pkgs/build-support/bintools-wrapper";
    in
    pkgs.symlinkJoin {
      name = "mold";
      paths = [ pkgs.mold ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      suffixSalt = lib.replaceStrings [ "-" "." ] [ "_" "_" ] pkgs.targetPlatform.config;
      postBuild = ''
        for bin in ${pkgs.mold}/bin/*; do
          rm $out/bin/"$(basename "$bin")"

          export prog="$bin"
          substituteAll "${bintools-wrapper}/ld-wrapper.sh" $out/bin/"$(basename "$bin")"
          chmod +x $out/bin/"$(basename "$bin")"

          mkdir -p $out/nix-support
          substituteAll "${bintools-wrapper}/add-flags.sh" $out/nix-support/add-flags.sh
          substituteAll "${bintools-wrapper}/add-hardening.sh" $out/nix-support/add-hardening.sh
          substituteAll "${bintools-wrapper}/../wrapper-common/utils.bash" $out/nix-support/utils.bash
        done
      '';
    };
in
{ toolchain ? null
, channel ? defaultChannel
, components ? [
    "rustc"
    "cargo"
    "clippy"
    "rust-analysis"
    "rust-src"
    "llvm-tools-preview"
  ]
, defaultCargoBuildTarget ? null
, args ? { }
, componentTargetsChannelName ? "stable"
, componentTargets ? [ ]

, clang ? pkgs.llvmPackages_14.clang
, libclang ? pkgs.llvmPackages_14.libclang.lib
, clang-unwrapped ? pkgs.llvmPackages_14.clang-unwrapped
, useMold ? pkgs.stdenv.isLinux
, isLintShell ? false
}:
let
  toolchain' =
    if toolchain != null then
      toolchain
    else
      (fenix.packages.${system}.combine (
        (map (component: channel.${component}) components)
        ++ (map (target: fenix.packages.${system}.targets.${target}.${componentTargetsChannelName}.rust-std) componentTargets)
      ));

  target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] pkgs.stdenv.buildPlatform.config;
  target_underscores_upper = lib.strings.toUpper target_underscores;

  nativeLLvmConfigPkg = targetLlvmConfigWrapper {
    clangPkg = clang;
    libClangPkg = clang-unwrapped.lib;
  };

  # TODO: unclear if this belongs here, or in `default` toolchain? or maybe conditional on being native?
  # figure out when someone complains
  argsCommon = lib.optionalAttrs (!isLintShell) ({
    LLVM_CONFIG_PATH = "${universalLlvmConfig}/bin/llvm-config";
    LLVM_CONFIG_PATH_native = "${nativeLLvmConfigPkg}/bin/llvm-config";
    "LLVM_CONFIG_PATH_${target_underscores}" = "${nativeLLvmConfigPkg}/bin/llvm-config";

    # bindgen expect native clang available here, so it's OK to set it globally,
    # should not break cross-compilation
    LIBCLANG_PATH = "${libclang.lib}/lib/";

    CC = "${clang}/bin/clang";
    CXX = "${clang}/bin/clang++";
  }
  # Note: do not touch MacOS's linker, stuff is brittle there
  # Also seems like Darwin can't handle mold or compress-debug-sections
  // lib.optionalAttrs (pkgs.stdenv.isLinux) {
    # just use newer clang
    "CARGO_TARGET_${target_underscores_upper}_LINKER" = "${clang}/bin/clang";
    # native toolchain default settings
    "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" =
      if useMold then
        "-C link-arg=-fuse-ld=mold -C link-arg=-Wl,--compress-debug-sections=zlib"
      else
        "-C link-arg=-Wl,--compress-debug-sections=zlib";

    nativeBuildInputs = lib.optionals useMold [ mold-wrapped ];
  });
  shellArgs = argsCommon // args;
  buildArgs =
    if defaultCargoBuildTarget != null then
      shellArgs // {
        CARGO_BUILD_TARGET = defaultCargoBuildTarget;
      }
    else
      shellArgs;

  # this can't be a method on `craneLib` because it basically constructs the `craneLib`
  craneLib' = (enhanceCrane (crane.lib.${system}.overrideToolchain toolchain')).overrideArgs buildArgs;
in
{
  toolchain = toolchain';
  inherit components componentTargets;
  args = buildArgs;
  inherit shellArgs;
  craneLib = craneLib';
}
