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

(outputsFn craneLib) //
(profilesFn craneLib) //
(mapWithToolchains
  (toolchainName: craneLib: profilesFn craneLib)
  toolchains)

