{ lib
, pkgs
, system
, android-nixpkgs
, mkFenixToolchain
}:
let
  defaultAndroidSdk =
    android-nixpkgs.sdk."${system}" (sdkPkgs: with sdkPkgs; [
      cmdline-tools-latest
      build-tools-32-0-0
      platform-tools
      platforms-android-31
      emulator
      ndk-bundle
    ]);
in
{ target
, androidTarget ? target
, arch
, androidVer ? 31
, androidSdk ? defaultAndroidSdk
}:

let
  ldLinkerWrapper =
    ld: ldflags:
    pkgs.writeShellScriptBin "ld" ''
      exec "${ld}" ${ldflags} "$@"
    '';
  target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] target;
  target_underscores_upper = lib.strings.toUpper target_underscores;

  androidSdkPrebuilt =
    if system == "x86_64-linux" then
      "${androidSdk}/share/android-sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64"
    else if system == "x86_64-darwin" then
      "${androidSdk}/share/android-sdk/ndk-bundle/toolchains/llvm/prebuilt/darwin-x86_64"
    else throw "Missing mapping for ${target} toolchain on ${system}, PRs welcome";

  ld_flags = "--sysroot ${androidSdkPrebuilt}/sysroot -L ${androidSdkPrebuilt}/sysroot/usr/lib/${androidTarget}/${toString androidVer}/ -L ${androidSdkPrebuilt}/sysroot/usr/lib/${androidTarget} -L ${androidSdkPrebuilt}/lib64/clang/12.0.5/lib/linux/${arch}/";
in
mkFenixToolchain {
  componentTargets = [ target ];
  defaultCargoBuildTarget = target;
  args = {
    "CC_${target_underscores}" = "${androidSdkPrebuilt}/bin/clang";
    "CXX_${target_underscores}" = "${androidSdkPrebuilt}/bin/clang++";
    "LD_${target_underscores}" = "${androidSdkPrebuilt}/bin/ld";
    "LDFLAGS_${target_underscores}" = ld_flags;
    "CARGO_TARGET_${target_underscores_upper}_LINKER" = "${ldLinkerWrapper "${androidSdkPrebuilt}/bin/ld" ld_flags}/bin/ld";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk/";
    ANDROID_HOME = "${androidSdk}/share/android-sdk/";
  };
}

