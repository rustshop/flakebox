{ fenix
, config
, system
, pkgs
}:
let defaultChannel = fenix.packages.${system}.${config.toolchain.channel.default}; in
{ channel ? defaultChannel
, components ? [
    "rustc"
    "cargo"
    "clippy"
    "rust-analysis"
    "rust-src"
    "llvm-tools-preview"
  ]
, envs ? ""
, args ? { }
, crossTargetsChannelName ? "stable"
, crossTargets ? [ ]
}:
let
  toolchain = fenix.packages.${system}.combine (
    (map (component: channel.${component}) components) ++
    (map (target: fenix.packages.${system}.targets.${target}.${crossTargetsChannelName}.rust-std) crossTargets)
  );
in
{
  inherit envs args toolchain;
}
