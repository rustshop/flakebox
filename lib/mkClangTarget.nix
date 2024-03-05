{ lib
, pkgs
, system
, mkTarget
, mergeArgs
}:
{ target
, clang
, binPrefix ? ""
, buildInputs ? [ ]
, nativeBuildInputs ? [ ]
, llvmConfigPkg ? clang
, args ? { }
, ...
}@mkClangTargetArgs:
{ extraRustFlags ? ""
, ...
}@args:
let
  target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] target;
  target_underscores_upper = lib.strings.toUpper target_underscores;
  combinedArgs = mergeArgs
    {
      # For bindgen, through universal-llvm-config
      "LLVM_CONFIG_PATH_${target_underscores}" = "${llvmConfigPkg}/bin/llvm-config";

      "CC_${target_underscores}" = "${clang}/bin/${binPrefix}clang";
      "CXX_${target_underscores}" = "${clang}/bin/${binPrefix}clang++";
      "AR_${target_underscores}" = "${clang}/bin/${binPrefix}ar";
      "LD_${target_underscores}" = "${clang}/bin/${binPrefix}clang";
      "CARGO_TARGET_${target_underscores_upper}_LINKER" = "${clang}/bin/${binPrefix}clang";
      "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" = "-C link-arg=-fuse-ld=${clang}/bin/${binPrefix}ld -C link-arg=-Wl,--compress-debug-sections=zlib ${extraRustFlags}";

      inherit buildInputs nativeBuildInputs;
    }
    (mkClangTargetArgs.args or { });
in
mkTarget
{
  inherit target;
  args = combinedArgs;
}
  args
