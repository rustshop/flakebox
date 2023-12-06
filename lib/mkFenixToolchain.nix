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
, extraRustFlags ? ""
, componentTargetsChannelName ? "stable"
, componentTargets ? [ ]
, clang ? pkgs.llvmPackages_16.clang
, libclang ? pkgs.llvmPackages_16.libclang.lib
, clang-unwrapped ? pkgs.llvmPackages_16.clang-unwrapped
, stdenv ? pkgs.stdenv
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
  commonArgs = mergeArgs args (lib.optionalAttrs (!isLintShell) ({
    LLVM_CONFIG_PATH = "${universalLlvmConfig}/bin/llvm-config";
    LLVM_CONFIG_PATH_native = "${nativeLLvmConfigPkg}/bin/llvm-config";
    "LLVM_CONFIG_PATH_${target_underscores}" = "${nativeLLvmConfigPkg}/bin/llvm-config";

    # bindgen expect native clang available here, so it's OK to set it globally,
    # should not break cross-compilation
    LIBCLANG_PATH = "${libclang.lib}/lib/";

    "CC_${target_underscores}" = "${clang}/bin/clang";
    "CXX_${target_underscores}" = "${clang}/bin/clang++";
    "LD_${target_underscores}" = "${clang}/bin/clang";
    "AR_${target_underscores}" = "${clang}/bin/ar";

    # just use newer clang, default to its ld for linking
    "CARGO_TARGET_${target_underscores_upper}_LINKER" = "${clang}/bin/clang";
    "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" = "-C link-arg=-fuse-ld=${clang}/bin/ld ${extraRustFlags}";

    # setting CC and CXX can't be done via a standard, but if we set `stdenv`
    # craneLib will pick up from `args`, and `mkDevShell` will handle manually
    # for some reason then we need to set `CC` and `CXX` here as well
    "CC" = "${clang}/bin/clang";
    "CXX" = "${clang}/bin/clang++";
    "LD" = "${clang}/bin/clang";
    "AR" = "${clang}/bin/ar";
  } //
  # On Linux (optionally) use mold and compress-debug-sections
  lib.optionalAttrs (pkgs.stdenv.isLinux) {
    # native toolchain default settings
    "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" =
      if useMold then
        "-C link-arg=-fuse-ld=mold -C link-arg=-Wl,--compress-debug-sections=zlib ${extraRustFlags}"
      else
        "-C link-arg=-Wl,--compress-debug-sections=zlib ${extraRustFlags}";

    nativeBuildInputs = lib.optionals useMold [ pkgs.mold-wrapped ];
  }));
  shellArgs = { };
  buildArgs =
    if defaultCargoBuildTarget != null then {
      CARGO_BUILD_TARGET = defaultCargoBuildTarget;
    } else { };

  # this can't be a method on `craneLib` because it basically constructs the `craneLib`
  craneLib' = (enhanceCrane (crane.lib.${system}.overrideToolchain toolchain')).overrideArgs ((mergeArgs commonArgs buildArgs) // { inherit stdenv; });
in
{
  toolchain = toolchain';
  inherit components componentTargets;
  inherit commonArgs shellArgs buildArgs stdenv;
  craneLib = craneLib';
}
