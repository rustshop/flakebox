{ lib
, pkgs
, system
, android-nixpkgs
, mkTarget
, mergeArgs
, defaultClang
, defaultClangUnwrapped
}:
{ target
, clang ? defaultClang
, llvmConfigPkg ? clang
, clang-unwrapped ? defaultClangUnwrapped
, binPrefix ? ""
, buildInputs ? [ ]
, nativeBuildInputs ? [ ]
, args ? { }
, ...
}@mkClangTargetArgs:
{ extraRustFlags ? ""
, ...
}@args:
let
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
  target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] target;
  target_underscores_upper = lib.strings.toUpper target_underscores;
  combinedArgs = mergeArgs
    {
      # For older bindgen, through universal-llvm-config
      "LLVM_CONFIG_PATH_${target_underscores}" = "${target-llvm-config-wrapper}/bin/llvm-config";

      "CC_${target_underscores}" = "/usr/bin/clang";
      "CXX_${target_underscores}" = "/usr/bin/clang++";
      ## cc or ld?
      "LD_${target_underscores}" = "/usr/bin/cc";

      "CARGO_TARGET_${target_underscores_upper}_LINKER" = "/usr/bin/clang";
      "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" = "-C link-arg=-fuse-ld=/usr/bin/ld ${extraRustFlags}";

      nativeBuildInputs = [ target-clang-wrapper ];
    }
    (mkClangTargetArgs.args or { });
in
mkTarget
{
  inherit target;
  args = combinedArgs;
}
  args
