{ fenix
, config
, system
, pkgs
, crane
, enhanceCrane
, mergeArgs
, universalLlvmConfig
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
  argsUniversalLlvmConfig = {
    LLVM_CONFIG_PATH = "${universalLlvmConfig}/bin/llvm-config";
  };
  shellArgs = argsUniversalLlvmConfig // args;
  buildArgs =
    if defaultCargoBuildTarget != null then
      shellArgs // {
        CARGO_BUILD_TARGET = defaultCargoBuildTarget;
      }
    else
      shellArgs;
  craneLib' = (enhanceCrane (crane.lib.${system}.overrideToolchain toolchain')).overrideArgs buildArgs;
in
{
  toolchain = toolchain';
  inherit components componentTargets;
  args = buildArgs;
  inherit shellArgs;
  craneLib = craneLib';
}
