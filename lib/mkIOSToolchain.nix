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

  # make bindgen (clang-sys) crate use /usr/bin/clang instead of NixOS
  # clang
  # https://github.com/KyleMayes/clang-sys/blob/b7992e864eaa2c8cb5c014a52074b962f257e29b/src/support.rs#L55
  bindgen-clang = pkgs.writeShellScriptBin "${target}-clang" ''
    exec /usr/bin/clang "$@"
  '';
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

    nativeBuildInputs = [ bindgen-clang ];
  };
}

