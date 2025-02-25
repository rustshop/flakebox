{
  mkFenixToolchain,
  craneMkLib,
  mapWithToolchains,
  mkTarget,
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
}:
outputsFn:
let
  profilesFn = craneLib: craneLib.mapWithProfiles outputsFn profiles;
in
(mapWithToolchains outputsFn { default = toolchains.default; }).default
// (mapWithToolchains profilesFn { default = toolchains.default; }).default
// (mapWithToolchains profilesFn toolchains)
