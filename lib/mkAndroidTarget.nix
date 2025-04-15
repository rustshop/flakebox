{
  lib,
  pkgs,
  system,
  android-nixpkgs,
  mkTarget,
}:
let
  defaultAndroidSdk = android-nixpkgs.sdk."${system}" (
    sdkPkgs: with sdkPkgs; [
      cmdline-tools-latest
      build-tools-32-0-0
      platform-tools
      platforms-android-32
      emulator
      ndk-25-2-9519653
    ]
  );
in
{
  target,
  targetBinPrefix ? target,
  androidTarget ? target,
  arch,
  androidVer ? 32,
  ...
}:
let
  defaultAndroidVer = androidVer;
in
{
  extraRustFlags ? "",
  androidVer ? defaultAndroidVer,
  androidSdk ? defaultAndroidSdk,
  androidApiLevel ? 24,
  ...
}@mkTargetArgs:
let
  target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] target;
  target_underscores_upper = lib.strings.toUpper target_underscores;

  ldLinkerWrapper =
    ld: ldflags:
    pkgs.writeShellScriptBin "ld" ''
      exec "${ld}" ${ldflags} "$@"
    '';
  androidSdkPrebuilt =
    if system == "x86_64-linux" then
      "${androidSdk}/share/android-sdk/ndk/25.2.9519653/toolchains/llvm/prebuilt/linux-x86_64"
    else if system == "x86_64-darwin" then
      "${androidSdk}/share/android-sdk/ndk/25.2.9519653/toolchains/llvm/prebuilt/darwin-x86_64"
    else if system == "aarch64-darwin" then
      # uses the x86_64 binaries, as aarch64 are not available (yet?)
      "${androidSdk}/share/android-sdk/ndk/25.2.9519653/toolchains/llvm/prebuilt/darwin-x86_64"
    else
      throw "Missing mapping for ${target} toolchain on ${system}, PRs welcome";

  readFileNoNewline = file: builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile file);

  cflags = readFileNoNewline (
    pkgs.runCommand "llvm-config-cflags" { } ''
      ${androidSdkPrebuilt}/bin/llvm-config --cflags > $out
    ''
  );
  cppflags = readFileNoNewline (
    pkgs.runCommand "llvm-config-cppflags" { } ''
      ${androidSdkPrebuilt}/bin/llvm-config --cppflags > $out
    ''
  );

  ldflags = "";
in
mkTarget {
  inherit target;
  canUseMold = false;
  args = {
    # For bindgen, through universal-llvm-config
    "LLVM_CONFIG_PATH_${target_underscores}" = "${androidSdkPrebuilt}/bin/llvm-config";

    # `cc` crate wants these
    "CC_${target_underscores}" =
      "${androidSdkPrebuilt}/bin/${targetBinPrefix}${toString androidApiLevel}-clang";
    "CFLAGS_${target_underscores}" = cflags;
    "CXXFLAGS_${target_underscores}" = cppflags;
    "CXX_${target_underscores}" =
      "${androidSdkPrebuilt}/bin/${targetBinPrefix}${toString androidApiLevel}-clang++";
    # "LD_${target_underscores}" = "${androidSdkPrebuilt}/bin/ld";
    "LD_${target_underscores}" =
      "${androidSdkPrebuilt}/bin/${targetBinPrefix}${toString androidApiLevel}-clang";

    "LDFLAGS_${target_underscores}" = ldflags;

    # This used to be needed needed
    # # "CARGO_TARGET_${target_underscores_upper}_LINKER" =
    # #   "${ldLinkerWrapper "${androidSdkPrebuilt}/bin/ld" ldflags}/bin/ld";
    "CARGO_TARGET_${target_underscores_upper}_LINKER" =
      "${androidSdkPrebuilt}/bin/${targetBinPrefix}${toString androidApiLevel}-clang";
    "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" = "${extraRustFlags}";

    # TODO: not clear if this belongs here, especially in presence of mixed android toolchains, this could fall apart
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk/";
    ANDROID_HOME = "${androidSdk}/share/android-sdk/";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/25.2.9519653/";
  };
} mkTargetArgs
