{ pkgs
, mkFenixToolchain
, system
, config
, fenix
, lib
, android-nixpkgs
}:

{
  # this needs to be a function just to avoid some extra stuff in the result
  # though in the future, we could use it to parametrize what's being returned
}:


let

  # NDK we use for android cross compilation
  androidSdk =
    android-nixpkgs.sdk."${system}" (sdkPkgs: with sdkPkgs; [
      cmdline-tools-latest
      build-tools-32-0-0
      platform-tools
      platforms-android-31
      emulator
      ndk-bundle
    ]);


  # From https://github.com/rust-mobile/cargo-apk/commit/4956b87f56f2854e2b3452b83b65b00224757d41
  # > Rust still searches for libgcc even though [85806] replaces internal use
  # > with libunwind, especially now that the Android NDK (since r23-beta3)
  # > doesn't ship with any of gcc anymore.  The apparent solution is to build
  # > your application with nightly and compile std locally (`-Zbuild-std`),
  # > but that is not desired for the majority of users.  [7339] suggests to
  # > provide a local `libgcc.a` as linker script, which simply redirects
  # > linking to `libunwind` instead - and that has proven to work fine so
  # > far.
  # >
  # > Instead of shipping this file with the crate or writing it to an existing
  # > link-search directory on the system, we write it to a new directory that
  # > can be easily passed or removed to `rustc`, say in the event that a user
  # > switches to an older NDK and builds without cleaning.  For this we need
  # > to switch from `cargo build` to `cargo rustc`, but the existing
  # > arguments and desired workflow remain identical.
  # >
  # > [85806]: rust-lang/rust#85806
  # > [7339]: termux/termux-packages#7339 (comment)

  fake-libgcc-gen = arch: pkgs.stdenv.mkDerivation {
    pname = "fake-libgcc";
    version = "0.1.0";

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/lib
      # on different architectures there will be different (but only a single one) libunwind.a for the given target
      # so use `find` and symlink it
      ln -s "`find ${androidSdk}/share/android-sdk/ndk-bundle/toolchains/llvm/prebuilt | grep ${arch}/libunwind.a`" $out/lib/libgcc.a
    '';
  };

in
{
  default = mkFenixToolchain {
    toolchain = config.toolchain.default;
  };
  stable = mkFenixToolchain {
    toolchain = config.toolchain.stable;
  };
  nightly = mkFenixToolchain {
    toolchain = config.toolchain.nightly;
  };
  aarch64-linux = mkFenixToolchain {
    componentTargets = [ "aarch64-unknown-linux-gnu" ];
    defaultCargoBuildTarget = "aarch64-unknown-linux-gnu";
    args = prev:

      let
        clang = pkgs.pkgsCross.aarch64-multiplatform.buildPackages.clang;
      in
      {
        # CC_aarch64-unknown-linux-gnu = "aarch64-unknown-linux-gnu-clang";
        # CXX_aarch64-unknown-linux-gnu = "aarch64-unknown-linux-gnu-clang++";
        # AR_aarch64-unknown-linux-gnu = "aarch64-unknown-linux-gnu-clang";
        # LD_aarch64-unknown-linux-gnu = "aarch64-unknown-linux-gnu-lld";
        # CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "aarch64-unknown-linux-gnu-clang";
        CC_aarch64-unknown-linux-gnu = "${clang}/bin/aarch64-unknown-linux-gnu-clang";
        CXX_aarch64-unknown-linux-gnu = "${clang}/bin/aarch64-unknown-linux-gnu-clang++";
        AR_aarch64-unknown-linux-gnu = "${clang}/bin/aarch64-unknown-linux-gnu-clang";
        LD_aarch64-unknown-linux-gnu = "${clang}/bin/aarch64-unknown-linux-gnu-lld";
        CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "${clang}/bin/aarch64-unknown-linux-gnu-clang";

        CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS = "-C link-arg=-Wl,--compress-debug-sections=zlib -C link-arg=-fuse-ld=mold";

        buildInputs = prev.buildInputs or [ ] ++ [
          # pkgs.pkgsCross.aarch64-multiplatform.clangStdenv.cc
          # pkgs.pkgsCross.aarch64-multiplatform.gcc.cc.libgcc
        ];
      };
  };
  x86_64-linux = mkFenixToolchain {
    componentTargets = [ "x86_64-unknown-linux-gnu" ];
    defaultCargoBuildTarget = "x86_64-unknown-linux-gnu";
    args = prev: (
      let clang = pkgs.clang;
      in {
        CC_x86_64-unknown-linux-gnu = "${clang}/bin/clang";
        CXX_x86_64-unknown-linux-gnu = "${clang}/bin/clang++";
        AR_x86_64-unknown-linux-gnu = "${clang}/bin/clang";
        LD_x86_64-unknown-linux-gnu = "${clang}/bin/lld";
        CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER = "${clang}/bin/clang";
        CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUSTFLAGS = "-C link-arg=-Wl,--compress-debug-sections=zlib -C link-arg=-fuse-ld=mold";

        buildInputs = prev.buildInputs or [ ] ++ [
          # pkgs.pkgsCross.gnu64.gcc.cc.libgcc
        ];
      }
    );
  };
  i686-linux = mkFenixToolchain {
    componentTargets = [ "i686-unknown-linux-gnu" ];
    defaultCargoBuildTarget = "i686-unknown-linux-gnu";
    args = prev: (
      let
        clang = pkgs.clang;
        gnu32 = pkgs.pkgsCross.gnu32.gcc.cc;
      in
      {
        CC_i686-unknown-linux-gnu = "${clang}/bin/clang";
        CXX_i686-unknown-linux-gnu = "${clang}/bin/clang++";
        AR_i686-unknown-linux-gnu = "${clang}/bin/clang";
        LD_i686-unknown-linux-gnu = "${clang}/bin/lld";
        CARGO_TARGET_I686_UNKNOWN_LINUX_GNU_LINKER = "${clang}/bin/clang";

        # CC_i686-unknown-linux-gnu = "${gnu32}/bin/i686-unknown-linux-gnu-cc";
        # CXX_i686-unknown-linux-gnu = "${gnu32}/bin/i686-unknown-linux-gnu-c++";
        # AR_i686-unknown-linux-gnu = "${gnu32}/bin/i686-unknown-linux-gnu-ar";
        # LD_i686-unknown-linux-gnu = "${gnu32}/bin/i686-unknown-linux-gnu-ld";
        # CARGO_TARGET_I686_UNKNOWN_LINUX_GNU_LINKER = "${gnu32}/bin/i686-unknown-linux-gnu-ld";

        CARGO_TARGET_I686_UNKNOWN_LINUX_GNU_RUSTFLAGS = "-C link-arg=-Wl,--compress-debug-sections=zlib";


        buildInputs = prev.buildInputs or [ ] ++ [
          # pkgs.pkgsCross.gnu32.gcc.cc.libgcc
          # pkgs.gcc.cc.libgcc
        ];
      }
    );
  };
  # NOTE: broken, need to figure out
  # NOTE: probably only works on MacOS
  # https://stackoverflow.com/questions/4391192/why-do-i-get-cc1plus-error-unrecognized-command-line-option-arch
  aarch64-darwin = mkFenixToolchain {
    componentTargets = [ "aarch64-apple-darwin" ];
    defaultCargoBuildTarget = "aarch64-apple-darwin";
    args = prev: ({ } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER =
        let
          inherit (pkgs.pkgsCross.aarch64-multiplatform.stdenv) cc;
        in
        "${cc}/bin/${cc.targetPrefix}cc";
    });
  };
  x86_64-darwin = mkFenixToolchain {
    componentTargets = [ "x86_64-apple-darwin" ];
    defaultCargoBuildTarget = "x86_64-apple-darwin";
    args = prev: ({ } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      CARGO_TARGET_x86_64_APPLE_DARWIN_LINKER =
        let
          inherit (pkgs.pkgsCross.x86_64-darwin.stdenv) cc;
        in
        "${cc}/bin/${cc.targetPrefix}cc";
    });
  };

  aarch64-android =
    let
      linkerWrapper =
        # ld: target:
        #   let
        #     target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] target;
        #     target_upper = lib.strings.toUpper target_underscores;
        #     target_lower = lib.strings.toLower target_underscores;
        #   in

        # >&2 echo "WRAPPER: $LD_${target_lower}" $LDFLAGS_${target_lower} $LDFALGS_${target_upper}
        # exec "${ld}" $LDFLAGS_${target_lower} $LDFALGS_${target_upper} "$@"
        ld: ldflags:
        pkgs.writeShellScript "$flakebox-linker-wrapper-${target}" ''

          args=()

          # Iterate over each argument
          for arg in "$@"; do
              # If the argument is not 'xxx', add it to the array
              if [[ $arg != "-nodefaultlibs" ]]; then
                  args+=("$arg")
                else
                  >&2 echo "removed $arg!"
              fi
          done
          exec "${ld}" ${ldflags} "''${args[@]}"
        '';

      clangLinkerWrapper =
        # ld: target:
        #   let
        #     target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] target;
        #     target_upper = lib.strings.toUpper target_underscores;
        #     target_lower = lib.strings.toLower target_underscores;
        #   in

        # >&2 echo "WRAPPER: $LD_${target_lower}" $LDFLAGS_${target_lower} $LDFALGS_${target_upper}
        # exec "${ld}" $LDFLAGS_${target_lower} $LDFALGS_${target_upper} "$@"
        ld: ldflags:
        pkgs.writeShellScriptBin "clang" ''

          args=()

          # Iterate over each argument
          for arg in "$@"; do
              # If the argument is not 'xxx', add it to the array
              if [[ $arg != "-nodefaultlibs" ]]; then
                  args+=("$arg")
                else
                  >&2 echo "removed $arg!"
              fi
          done
          exec "${ld}" ${ldflags} "''${args[@]}"
        '';
      ldLinkerWrapper =
        # ld: target:
        #   let
        #     target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] target;
        #     target_upper = lib.strings.toUpper target_underscores;
        #     target_lower = lib.strings.toLower target_underscores;
        #   in

        # >&2 echo "WRAPPER: $LD_${target_lower}" $LDFLAGS_${target_lower} $LDFALGS_${target_upper}
        # exec "${ld}" $LDFLAGS_${target_lower} $LDFALGS_${target_upper} "$@"
        ld: ldflags:
        pkgs.writeShellScriptBin "ld" ''

          exec "${ld}" ${ldflags} "$@"
        '';
      target = "aarch64-linux-android";
      target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] target;
      androidVer = "31";

      arch = "aarch64";

      # fake-libgcc-x86_64 = fake-libgcc-gen "x86_64";
      # fake-libgcc-aarch64 = fake-libgcc-gen "aarch64";
      # fake-libgcc-arm = fake-libgcc-gen "arm";
      # fake-libgcc-i386 = fake-libgcc-gen "i386";


      androidSdkPrebuilt =
        if system == "x86_64-linux" then
          "${androidSdk}/share/android-sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64"
        else throw "Missing mapping for ${target} toolchain on ${system}, PRs welcome";

      # ld_flags = "-L ${fake-libgcc-gen arch}/lib --sysroot ${androidSdkPrebuilt}/sysroot -pie -L ${androidSdkPrebuilt}/sysroot/usr/lib/aarch64-linux-android/${androidVer}/ -L ${androidSdkPrebuilt}/sysroot/usr/lib/aarch64-linux-android";
      ld_flags = "--sysroot ${androidSdkPrebuilt}/sysroot -pie -L ${androidSdkPrebuilt}/sysroot/usr/lib/aarch64-linux-android/${androidVer}/ -L ${androidSdkPrebuilt}/sysroot/usr/lib/aarch64-linux-android -L ${androidSdkPrebuilt}/lib64/clang/12.0.5/lib/linux/${arch}/";
      # ld_flags = "--sysroot ${androidSdkPrebuilt}/sysroot -pie";
    in
    mkFenixToolchain
      {
        componentTargets = [ target ];
        defaultCargoBuildTarget = target;
        args = prev: {

          "CC_${target_underscores}" = "${androidSdkPrebuilt}/bin/clang";
          "CXX_${target_underscores}" = "${androidSdkPrebuilt}/bin/clang++";
          "LD_${target_underscores}" = "${androidSdkPrebuilt}/bin/ld";
          "LDFLAGS_${target_underscores}" = ld_flags;
          CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER = "${ldLinkerWrapper "${androidSdkPrebuilt}/bin/ld" ld_flags}/bin/ld";
        };
      };

  # export CC_aarch64_linux_android="`find ${androidSdk}/share/android-sdk/ndk-bundle/toolchains/llvm/prebuilt/ | grep bin/clang$`"
  # export CXX_aarch64_linux_android="`find ${androidSdk}/share/android-sdk/ndk-bundle/toolchains/llvm/prebuilt/ | grep bin/clang++$`"
  # export LD_aarch64_linux_android="`find ${androidSdk}/share/android-sdk/ndk-bundle/toolchains/llvm/prebuilt/ | grep bin/ld$`"
  # export LDFLAGS_aarch64_linux_android="-L `find ${androidSdk}/share/android-sdk/ndk-bundle/toolchains/llvm/prebuilt/ -type d | grep sysroot/usr/lib/aarch64-linux-android/30$` -L `find ${androidSdk}/share/android-sdk/ndk-bundle/toolchains/llvm/prebuilt/ -type d | grep sysroot/usr/lib/aarch64-linux-android$` -L ${fake-libgcc-aarch64}/lib"

  wasm32-unknown = mkFenixToolchain {
    componentTargets = [ "wasm32-unknown-unknown" ];
    defaultCargoBuildTarget = "wasm32-unknown-unknown";
    args = prev: ({

      CC_wasm32_unknown_unknown = "${pkgs.llvmPackages_14.clang-unwrapped}/bin/clang-14";
      CFLAGS_wasm32_unknown_unknown = "-I ${pkgs.llvmPackages_14.libclang.lib}/lib/clang/14.0.6/include/";

    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      AR_wasm32_unknown_unknown = "${pkgs.llvmPackages_14.llvm}/bin/llvm-ar";
    });
  };

}

