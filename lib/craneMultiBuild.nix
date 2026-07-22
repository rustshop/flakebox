{
  craneMkLib,
  mkStdToolchains,
  lib,
  pkgs,
}:
let
  craneLib' = craneMkLib pkgs;
in
{
  toolchains ? mkStdToolchains { },
  profiles ? [
    "dev"
    "ci"
    "release"
  ],
  craneLib ? craneLib',
  argsFor ? null,
}:
outputsFn:
let
  dependencyRoles = [
    "buildInputs"
    "nativeBuildInputs"
    "depsBuildBuild"
  ];

  craneLibFor =
    toolchainName: toolchain:
    let
      dependencyContext = toolchain.dependencyContext or { };
      missingRole =
        role:
        let
          reason =
            dependencyContext.unavailablePackages.${role}
              or "the toolchain does not define a dependency context for this role";
        in
        throw "craneMultiBuild argsFor: toolchain/cell `${toolchainName}` cannot provide `packages.${role}`: ${reason}";
      packages = lib.genAttrs dependencyRoles (
        role:
        if dependencyContext ? packages && builtins.hasAttr role dependencyContext.packages then
          dependencyContext.packages.${role}
        else
          missingRole role
      );
      capabilities.targetBuildInputs =
        dependencyContext ? packages && dependencyContext.packages ? buildInputs;
      baseCraneLib = toolchain.craneLib.overrideArgs { inherit toolchainName; };
    in
    if argsFor == null then
      baseCraneLib
    else
      baseCraneLib.overrideArgs (argsFor {
        inherit
          capabilities
          packages
          toolchainName
          ;
      });

  # Resolve cell arguments here, before any profile mapping. Besides keeping
  # `argsFor` profile-independent, this lets every profile reuse the same
  # cell-local Crane library.
  cellCraneLibs = lib.mapAttrs craneLibFor toolchains;
  defaultCraneLib = cellCraneLibs.default;
  profilesFn = craneLib: craneLib.mapWithProfiles outputsFn profiles;
in
outputsFn defaultCraneLib
// profilesFn defaultCraneLib
// lib.mapAttrs (_: profilesFn) cellCraneLibs
