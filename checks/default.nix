{
  pkgs,
  mkLib,
  full ? false,
}:
let
  inherit (pkgs) lib;

  onlyDrvs = lib.filterAttrs (_: lib.isDerivation);
in
onlyDrvs (
  lib.makeScope pkgs.newScope (
    self:
    let
      flakeboxLib = mkLib pkgs { };
      callPackage = self.newScope { inherit flakeboxLib; };
    in
    {
      workspaceSanity = callPackage ./workspace-sanity { };
      workspaceCross = callPackage ./workspace-cross-compile { inherit full; };
      customStdenv = callPackage ./custom-stdenv { };
      nextest = callPackage ./nextest { };
      mergeArgsTests = callPackage ./mergeArgs-tests.nix { };
    }
  )
)
