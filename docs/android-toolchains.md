# Android toolchains

Android toolchains uses [`android-nixpkgs`](https://github.com/tadfisher/android-nixpkgs`) to
source precompiled Android toolchains.

Toolchain short-names:

* `aarch64-android` - `aarch64-linux-android` target
* `arm-android` - `arm-linux-androideabi` target
* `armv7-android` - `armv7-linux-androideabi` target
* `x86_64-android` - `x86_64-linux-android` target
* `i686-android` - `i686-linux-android` target


It's possible to override the default components of the toolchain with:


```nix
let
  androidSdk =
    android-nixpkgs.sdk."${system}" (sdkPkgs: with sdkPkgs; [
      cmdline-tools-latest
      build-tools-30-0-3
      build-tools-32-0-0
      build-tools-33-0-0
      platform-tools
      platforms-android-31
      platforms-android-33
      emulator
      ndk-bundle
      ndk-27-1-12297006
      cmake-3-22-1
      patcher-v4
      tools
    ]);

  toolchains = (pkgs.lib.getAttrs [
    "default"
    "aarch64-android"
    "x86_64-android"
    "arm-android"
    "armv7-android"
  ]
    (flakeboxLib.mkStdFenixToolchains {
      inherit androidSdk;
    })
  );

  toolchain = flakeboxLib.mkFenixMultiToolchain {
    inherit toolchains;
  };
in
{}
```
