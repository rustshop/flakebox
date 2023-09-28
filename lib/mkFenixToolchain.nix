{ fenix
, config
, system
, pkgs
, crane
, enhanceCrane
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
, args ? { }
, crossTargetsChannelName ? "stable"
, crossTargets ? [ ]
}:
let
  toolchain' =
    if toolchain != null then
      toolchain
    else
      (fenix.packages.${system}.combine (
        (map (component: channel.${component}) components)
        ++ (map (target: fenix.packages.${system}.targets.${target}.${crossTargetsChannelName}.rust-std) crossTargets)
      ));
  craneLib' = enhanceCrane (crane.lib.${system}.overrideToolchain toolchain');
in
{
  toolchain = toolchain';
  craneLib = craneLib'.overrideArgs args;
}
