{ mkStdFenixToolchains
, craneLib
, mapWithToolchains
}:
let craneLib' = craneLib; in

{ toolchains ? mkStdFenixToolchains { }
, profiles ? [ "dev" "ci" "release" ]
, craneLib ? craneLib'
}: outputsFn:
let
  profilesFn = craneLib: craneLib.mapWithProfiles outputsFn profiles;
in
(mapWithToolchains outputsFn { default = toolchains.default; }).default //
(mapWithToolchains profilesFn { default = toolchains.default; }).default //
(mapWithToolchains profilesFn toolchains)

