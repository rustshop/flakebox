{ fenix
, config
, system
, pkgs
, crane
, enhanceCrane
, mergeArgs
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
  args' =
    if defaultCargoBuildTarget != null then
      args // { CARGO_BUILD_TARGET = defaultCargoBuildTarget; }
    else
      args;
  craneLib' = (enhanceCrane (crane.lib.${system}.overrideToolchain toolchain')).overrideArgs args';
in
{
  toolchain = toolchain';
  inherit components componentTargets;
  args = args';
  shellArgs = args;
  craneLib = craneLib';
}
