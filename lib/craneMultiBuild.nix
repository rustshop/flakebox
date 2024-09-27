{
  mkFenixToolchain,
  craneLib,
  mapWithToolchains,
  mkTarget,
  mkStdToolchains,
  lib,
}:
let
  craneLib' = craneLib;
in
{
  toolchains ? mkStdToolchains { },
  profiles ? [
    "dev"
    "ci"
    "release"
  ],
  craneLib ? craneLib',
}:
outputsFn:
let
  profilesFn = craneLib: craneLib.mapWithProfiles outputsFn profiles;
in
(mapWithToolchains outputsFn { default = toolchains.default; }).default
// (mapWithToolchains profilesFn { default = toolchains.default; }).default
// (mapWithToolchains profilesFn toolchains)
