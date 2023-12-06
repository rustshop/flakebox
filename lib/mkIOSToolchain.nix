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
  target-clang-wrapper = pkgs.writeShellScriptBin "${target}-clang" ''
    exec /usr/bin/clang "$@"
  '';

  # older bindgen (clang-sys) crate can be told to use /usr/bin/clang this way
  target-llvm-config-wrapper = pkgs.writeShellScriptBin "llvm-config" ''
    if [ "$1" == "--bindir" ]; then
      echo "/usr/bin/"
      exit 0
    fi
    exec llvm-config "$@"
  '';
in
mkFenixToolchain {
  inherit target;
  componentTargets = [ target ];
  defaultCargoBuildTarget = target;
  args = {
    # For older bindgen, through universal-llvm-config
    "LLVM_CONFIG_PATH_${target_underscores}" = "${target-llvm-config-wrapper}/bin/llvm-config";

    "CC_${target_underscores}" = "/usr/bin/clang";
    "CXX_${target_underscores}" = "/usr/bin/clang++";
    ## cc or ld?
    "LD_${target_underscores}" = "/usr/bin/cc";
    "CARGO_TARGET_${target_underscores_upper}_LINKER" = "/usr/bin/clang";

    nativeBuildInputs = [ target-clang-wrapper ];
  };
}

