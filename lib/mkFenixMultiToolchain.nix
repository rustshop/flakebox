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
let
  defaultChannelName = config.toolchain.channel.default;
  defaultChannel = fenix.packages.${system}.${defaultChannelName};
in
{ toolchains ? mkStdFenixToolchains { }
, componentTargetsChannelName ? defaultChannelName
, channel ? defaultChannel
, defaultCargoBuildTarget ? null
, commonArgs ? { }
, shellArgs ? { }
, buildArgs ? { }
, stdenv ? pkgs.stdenv
, componentTargets ? [ ]
}:
let
  toolchains' = builtins.attrValues toolchains;
  uniqueList = list: lib.foldl' (acc: elem: if lib.elem elem acc then acc else acc ++ [ elem ]) [ ] list;
  allComponents = uniqueList (builtins.concatLists (map (toolchain: toolchain.components) toolchains'));
  allComponentTargets = uniqueList (builtins.concatLists (map (toolchain: toolchain.componentTargets) toolchains'));
  allCommonArgs = lib.foldl
    (accCommonArgs: toolchainCommonArgs: mergeArgs accCommonArgs toolchainCommonArgs)
    commonArgs
    (map (toolchain: toolchain.commonArgs) toolchains');
  allShellArgs = lib.foldl
    (accShellArgs: toolchainShellArgs: mergeArgs accShellArgs toolchainShellArgs)
    shellArgs
    (map (toolchain: toolchain.shellArgs) toolchains');
  allBuildArgs = lib.foldl
    (accBuildArgs: toolchainBuildArgs: mergeArgs accBuildArgs toolchainBuildArgs)
    buildArgs
    (map (toolchain: toolchain.buildArgs) toolchains');
  allStdenv = lib.foldl
    (accBuildArgs: toolchainStdenv: toolchainStdenv)
    stdenv
    (map (toolchain: toolchain.stdenv) toolchains');
  toolchain' =
    (fenix.packages.${system}.combine (
      (map (component: channel.${component}) allComponents)
      ++ (map (target: fenix.packages.${system}.targets.${target}.${componentTargetsChannelName}.rust-std) allComponentTargets)
    ));
  craneLib' = (enhanceCrane (crane.lib.${system}.overrideToolchain toolchain')).overrideArgs ((mergeArgs allCommonArgs allBuildArgs) // { stdenv = allStdenv; });
  allBuildArgs' =
    if defaultCargoBuildTarget != null then
      allBuildArgs // { CARGO_BUILD_TARGET = defaultCargoBuildTarget; }
    else
      allBuildArgs;
in
{
  toolchain = toolchain';
  components = allComponents;
  componentsTargets = allComponentTargets;
  commonArgs = allCommonArgs;
  buildArgs = allBuildArgs';
  shellArgs = allShellArgs;
  craneLib = craneLib';
  stdenv = allStdenv;
}
