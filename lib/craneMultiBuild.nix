{
  mkFenixToolchain,
  craneLib,
  mapWithToolchains,
  mkTarget,
  mkStdToolchains,
  lib,
}: let
  craneLib' = craneLib;
in
  {
    buildInputs ? pkgs: [],
    nativeBuildInputs ? pkgs: [],
    profiles ? ["dev" "ci" "release"],
    craneLib ? craneLib',
    toolchains ? null,
  }: let
    argToolchains = if toolchains != null then toolchains else (mkStdToolchains {inherit buildInputs nativeBuildInputs;});
  in
    outputsFn: let
      profilesFn = craneLib: craneLib.mapWithProfiles outputsFn profiles;
    in
      (mapWithToolchains outputsFn {default = argToolchains.default;}).default
      // (mapWithToolchains profilesFn {default = argToolchains.default;}).default
      // (mapWithToolchains profilesFn argToolchains)
