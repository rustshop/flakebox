{
  fenix,
  config,
  system,
  pkgs,
  lib,
  crane,
  nixpkgs,
  enhanceCrane,
  mergeArgs,
  universalLlvmConfig,
  targetLlvmConfigWrapper,
  mkNativeTarget,
  defaultClang,
  defaultLibClang,
  defaultClangUnwrapped,
  defaultStdenv,
}:
{
  target ? pkgs.stdenv.buildPlatform.config,
  args ? { },
  # rust component targets to include
  componentTargets ? [ target ],
  canUseMold ? true,
  canUseWild ? false,
  isCalledByMkNativeTarget ? false,
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
  {
    extraRustFlags ? "",
    clang ? defaultClang,
    libclang ? defaultLibClang,
    clang-unwrapped ? defaultClangUnwrapped,
  }:
  let

    wild-wrapped =
      let
        bintools-wrapper = "${nixpkgs}/pkgs/build-support/bintools-wrapper";
      in
      pkgs.wrapBintoolsWith {
        bintools = pkgs.wild;
        extraBuildCommands = ''
          wrap ${pkgs.stdenv.cc.bintools.targetPrefix}ld.wild "${bintools-wrapper}/ld-wrapper.sh" ${pkgs.wild}/bin/ld.wild
          wrap ${pkgs.stdenv.cc.bintools.targetPrefix}wild "${bintools-wrapper}/ld-wrapper.sh" ${pkgs.wild}/bin/wild
        '';
      };

    # https://github.com/NixOS/nixpkgs/blob/f7ac75f242ca29f9160b97917dec8ebd4dfbe008/doc/release-notes/rl-2505.section.md?plain=1#L90
    fixedTarget = if target == "arm64-apple-darwin" then "aarch64-apple-darwin" else target;
    target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] fixedTarget;
    target_underscores_upper = lib.strings.toUpper target_underscores;

    nativeLLvmConfigPkg = targetLlvmConfigWrapper {
      clangPkg = clang;
      libClangPkg = clang-unwrapped.lib;
    };

    commonArgs = mergeArgs (mergeArgs
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

      }

      (
        if pkgs.stdenv.isLinux && config.linker.wild.enable && canUseWild && pkgs ? useWildLinker then
          {
            "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" =
              "-C link-arg=--ld-path=${wild-wrapped}/bin/wild ${extraRustFlags}";
          }
        else if
          config.linker.mold.enable
          && canUseMold
          && pkgs.stdenv.isLinux
          && pkgs.stdenvAdapters ? useMoldLinker
        then
          # mold only supported on Linux, and supports compressed debug sections
          {
            "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" =
              "-C link-arg=-fuse-ld=${pkgs.mold-wrapped}/bin/mold -C link-arg=-Wl,--compress-debug-sections=zlib ${extraRustFlags}";
          }
        else if pkgs.stdenv.isLinux then
          # compressed debug sections, only supported on Linux
          {
            "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" =
              "-C link-arg=-Wl,--compress-debug-sections=zlib ${extraRustFlags}";
          }
        else
          {
            "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" = "${extraRustFlags}";
          }
      )
    ) args;

  in
  {
    args = commonArgs;
    componentTargets = [ target ];
  }
