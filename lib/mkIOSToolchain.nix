{ lib
, pkgs
, system
, android-nixpkgs
, mkFenixToolchain
}:
{ target
}:

let
  target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] target;
  target_underscores_upper = lib.strings.toUpper target_underscores;

in
mkFenixToolchain {
  componentTargets = [ target ];
  defaultCargoBuildTarget = target;
  args = {
    "CC_${target_underscores}" = "/usr/bin/clang";
    "CXX_${target_underscores}" = "/usr/bin/clang++";
    ## cc or ld?
    "LD_${target_underscores}" = "/usr/bin/cc";
    "CARGO_TARGET_${target_underscores_upper}_LINKER" = "/usr/bin/clang";
  };
}

