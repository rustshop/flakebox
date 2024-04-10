{ fenix
, config
, system
, pkgs
, lib
, crane
, enhanceCrane
, mergeArgs
, universalLlvmConfig
, targetLlvmConfigWrapper
, mkNativeTarget
, defaultClang
, defaultLibClang
, defaultClangUnwrapped
, defaultStdenv
}:
{ target ? pkgs.stdenv.buildPlatform.config
, args ? { }
  # rust component targets to include
, componentTargets ? [ target ]
, canUseMold ? true
, isCalledByMkNativeTarget ? false
}:
let
  isNativeTarget = pkgs.stdenv.buildPlatform.config == target;
in
if (isNativeTarget && !isCalledByMkNativeTarget) then
# if we are trying to define a cross-compilation target to our own system, just use native target
# TODO: should we just not?
  mkNativeTarget { }
else
# a target is a function so it can be still overridden
  { extraRustFlags ? ""
  , clang ? defaultClang
  , libclang ? defaultLibClang
  , clang-unwrapped ? defaultClangUnwrapped
  }:
  let
    target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] target;
    target_underscores_upper = lib.strings.toUpper target_underscores;

    nativeLLvmConfigPkg = targetLlvmConfigWrapper {
      clangPkg = clang;
      libClangPkg = clang-unwrapped.lib;
    };

    commonArgs = mergeArgs
      {
        # NOTE: as this is not target specific, it's unclear if this should be set here
        # (every target is using mkTarget underneath), or once in `mkXYZToolchain`
        LLVM_CONFIG_PATH = "${universalLlvmConfig}/bin/llvm-config";
        LLVM_CONFIG_PATH_native = "${nativeLLvmConfigPkg}/bin/llvm-config";

        # bindgen expect native clang available here, so it's OK to set it globally,
        # should not break cross-compilation
        LIBCLANG_PATH = "${libclang.lib}/lib/";

        "CC_${target_underscores}" = "${clang}/bin/clang";
        "CXX_${target_underscores}" = "${clang}/bin/clang++";
        "LD_${target_underscores}" = "${clang}/bin/clang";
        "AR_${target_underscores}" = "${clang}/bin/ar";

        # just use newer clang, default to its ld for linking
        "CARGO_TARGET_${target_underscores_upper}_LINKER" = "${clang}/bin/clang";
        # TODO: why did I had it here before?
        # "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" = "-C link-arg=-fuse-ld=${clang}/bin/ld ${extraRustFlags}";

        "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" =
          # mold & compressed debug section support only when building on Linux
          if pkgs.stdenv.isLinux then
            if canUseMold then
              "-C link-arg=-fuse-ld=mold -C link-arg=-Wl,--compress-debug-sections=zlib ${extraRustFlags}"
            else
              "-C link-arg=-Wl,--compress-debug-sections=zlib ${extraRustFlags}"
          else
            "${extraRustFlags}";

        nativeBuildInputs = lib.optionals (pkgs.stdenv.isLinux && canUseMold) [
          pkgs.mold-wrapped
        ];
      }
      args;

  in
  {
    args = commonArgs;
    componentTargets = [ target ];
  }
