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
, defaultClang
, defaultLibClang
, defaultClangUnwrapped
, defaultStdenv
}:
let
  defaultChannelName = config.toolchain.channel;
  defaultComponents = config.toolchain.components;
in
{ targets
, channel ? defaultChannelName
, components ? defaultComponents
, defaultTarget ? null
, args ? { }
, extraRustFlags ? ""
, componentTargetsChannelName ? defaultChannelName
, componentTargets ? [ ]
, clang ? defaultClang
, libclang ? defaultLibClang
, clang-unwrapped ? defaultClangUnwrapped
, stdenv ? defaultStdenv
, isLintShell ? false
}:
let
  mergeTargets = targetFn: prev:
    let
      target = targetFn {
        inherit clang libclang clang-unwrapped extraRustFlags;
      };
    in
    {
      args = mergeArgs prev.args target.args;
      componentTargets = prev.componentTargets ++ target.componentTargets;
    };

  mergedTargets = lib.foldr mergeTargets
    {
      args = { };
      componentTargets = [ ];
    }
    (builtins.attrValues targets);

  toolchain =
    fenix.packages.${system}.combine (
      (map
        (component: fenix.packages.${system}.${channel}.${component})
        components
      )
      ++
      (map
        (target: fenix.packages.${system}.targets.${target}.${componentTargetsChannelName}.rust-std)
        mergedTargets.componentTargets
      )
    );

  commonArgs = mergeArgs mergedTargets.args args;
  shellArgs = { };
  buildArgs =
    if defaultTarget != null then {
      CARGO_BUILD_TARGET = defaultTarget;
    } else { };

  # this can't be a method on `craneLib` because it basically constructs the `craneLib`
  craneLib = (enhanceCrane (crane.lib.${system}.overrideToolchain toolchain)).overrideArgs ((mergeArgs commonArgs buildArgs) // { inherit stdenv; });
in
{
  inherit toolchain;
  inherit commonArgs shellArgs buildArgs stdenv;
  inherit craneLib;
}
