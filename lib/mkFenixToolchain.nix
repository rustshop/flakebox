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
let defaultChannel = fenix.packages.${system}.${config.toolchain.channel.default}; in
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

  nativeLLvmConfigPkg = targetLlvmConfigWrapper {
    clangPkg = pkgs.llvmPackages_14.clang;
    # clangPkg = pkgs.llvmPackages_14.clang-unwrapped.lib;
    libClangPkg = pkgs.llvmPackages_14.clang-unwrapped.lib;
  };

  # TODO: unclear if this belongs here, or in `default` toolchain? or maybe conditional on being native?
  # figure out when someone complains
  argsCommon =
    {
      LLVM_CONFIG_PATH = "${universalLlvmConfig}/bin/llvm-config";
      LLVM_CONFIG_PATH_native = "${nativeLLvmConfigPkg}/bin/llvm-config";
      "LLVM_CONFIG_PATH_${target_underscores}" = "${nativeLLvmConfigPkg}/bin/llvm-config";

      # llvm (llvm11) is often too old to compile things, so we use llvm14
      # nativeBuildInputs = [ pkgs.llvmPackages_14.clang ];
      # bindgen expect native clang available here, so it's OK to set it globally,
      # should not break cross-compilation
      LIBCLANG_PATH = "${pkgs.llvmPackages_14.libclang.lib}/lib/";
    };
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
