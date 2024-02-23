{ lib
, pkgs
, system
, mkTarget
, mergeArgs
, targetLlvmConfigWrapper
}:
{ buildInputs ? [ ]
, nativeBuildInputs ? [ ]
, args ? { }
, ...
}@mkNativeTargetArgs:
{ extraRustFlags ? ""
, clang ? pkgs.llvmPackages_16.clang
, llvmConfigPkg ? clang
, clang-unwrapped ? pkgs.llvmPackages_16.clang-unwrapped
, ...
}@args:
let
  target = pkgs.stdenv.buildPlatform.config;
  target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] target;
  target_underscores_upper = lib.strings.toUpper target_underscores;
  nativeLlvmConfigPkg = targetLlvmConfigWrapper {
    clangPkg = clang;
    libClangPkg = clang-unwrapped.lib;
  };
  combinedArgs = mergeArgs
    {
      # For bindgen, through universal-llvm-config
      # "LLVM_CONFIG_PATH_${target_underscores}" = "${llvmConfigPkg}/bin/llvm-config";
      "LLVM_CONFIG_PATH_${target_underscores}" = "${nativeLlvmConfigPkg}/bin/llvm-config";

      "CC_${target_underscores}" = "${clang}/bin/clang";
      "CXX_${target_underscores}" = "${clang}/bin/clang++";
      "AR_${target_underscores}" = "${clang}/bin/ar";
      "LD_${target_underscores}" = "${clang}/bin/ld";

      "CC" = "${clang}/bin/clang";
      "CXX" = "${clang}/bin/clang++";
      "AR" = "${clang}/bin/ar";
      "LD" = "${clang}/bin/ld";

      inherit buildInputs nativeBuildInputs;
    }
    (mkNativeTargetArgs.args or { });
in
mkTarget
{
  inherit target;
  args = combinedArgs;
  isCalledByMkNativeTarget = true;
}
  args
