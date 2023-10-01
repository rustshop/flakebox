{ fenix
, config
, system
, pkgs
, lib
, crane
, enhanceCrane
, mkStdFenixToolchains
, mergeArgs
}:
let defaultChannel = fenix.packages.${system}.${config.toolchain.channel.default};

in
{ toolchains ? mkStdFenixToolchains { }
, componentTargetsChannelName ? "stable"
, channel ? defaultChannel
, defaultCargoBuildTarget ? null
, args ? { }
, componentTargets ? [ ]
}:
let
  toolchains' = builtins.attrValues toolchains;
  uniqueList = list: lib.foldl' (acc: elem: if lib.elem elem acc then acc else acc ++ [ elem ]) [ ] list;
  allComponents = uniqueList (builtins.concatLists (map (toolchain: toolchain.components) toolchains'));
  allComponentTargets = uniqueList (builtins.concatLists (map (toolchain: toolchain.componentTargets) toolchains'));
  allArgs = lib.foldl
    (accShellArgs: toolchainShellArgs: mergeArgs accShellArgs toolchainShellArgs)
    args
    (map (toolchain: toolchain.shellArgs) toolchains');
  toolchain' =
    (fenix.packages.${system}.combine (
      (map (component: channel.${component}) allComponents)
      ++ (map (target: fenix.packages.${system}.targets.${target}.${componentTargetsChannelName}.rust-std) allComponentTargets)
    ));
  craneLib' = (enhanceCrane (crane.lib.${system}.overrideToolchain toolchain')).overrideArgs args';
  args' =
    if defaultCargoBuildTarget != null then
      allArgs // { CARGO_BUILD_TARGET = defaultCargoBuildTarget; }
    else
      allArgs;
in
{
  toolchain = toolchain';
  components = allComponents;
  componentsTargets = allComponentTargets;
  args = args';
  shellArgs = allArgs;
  craneLib = craneLib';
}
