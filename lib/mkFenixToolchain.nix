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
}:
let
  defaultChannel = fenix.packages.${system}.${config.toolchain.channel.default};
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

, clang ? pkgs.llvmPackages_16.clang
, libclang ? pkgs.llvmPackages_16.libclang.lib
, clang-unwrapped ? pkgs.llvmPackages_16.clang-unwrapped
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

    nativeBuildInputs = lib.optionals useMold [ pkgs.mold-wrapped ];
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
