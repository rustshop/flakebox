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

  # in theory `llvm-config` should work better than manually set paths
  # ldflags = readFileNoNewline (pkgs.runCommand "llvm-config-ldflags" { } ''
  #   ${androidSdkPrebuilt}/bin/llvm-config --ldflags > $out
  # '');
  # but in practice it doesn't
  ldflags = "--sysroot ${androidSdkPrebuilt}/sysroot -L ${androidSdkPrebuilt}/sysroot/usr/lib/${androidTarget}/${toString androidVer}/ -L ${androidSdkPrebuilt}/sysroot/usr/lib/${androidTarget} -L ${androidSdkPrebuilt}/lib64/clang/14.0.7/lib/linux/${arch}/";
in
mkTarget {
  inherit target;
  canUseMold = false;
  args = {
    # For bindgen, through universal-llvm-config
    "LLVM_CONFIG_PATH_${target_underscores}" = "${androidSdkPrebuilt}/bin/llvm-config";

    # `cc` crate wants these  
    "CC_${target_underscores}" = "${androidSdkPrebuilt}/bin/clang";
    "CFLAGS_${target_underscores}" = cflags;
    "CXXFLAGS_${target_underscores}" = cppflags;
    "CXX_${target_underscores}" = "${androidSdkPrebuilt}/bin/clang++";
    "LD_${target_underscores}" = "${androidSdkPrebuilt}/bin/ld";
    "LDFLAGS_${target_underscores}" = ldflags;

    # cargo needs this
    "CARGO_TARGET_${target_underscores_upper}_LINKER" = "${ldLinkerWrapper "${androidSdkPrebuilt}/bin/ld" ldflags}/bin/ld";
    "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" = "${extraRustFlags}";

    # TODO: not clear if this belongs here, especially in presence of mixed android toolchains, this could fall apart
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk/";
    ANDROID_HOME = "${androidSdk}/share/android-sdk/";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/25.2.9519653/";
  };
} mkTargetArgs
