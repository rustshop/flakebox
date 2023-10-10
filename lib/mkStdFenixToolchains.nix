{ pkgs
, mkFenixToolchain
, system
, config
, fenix
, lib
, android-nixpkgs
, mkAndroidToolchain
, mkIOSToolchain
, targetLlvmConfigWrapper
}:
{
  # androidSdk ? null
  ...
}@args:
let
  cleanedArgs =
    removeAttrs args [ "androidSdk" ];

  mkClangToolchain =
    { target
    , clang
    , binPrefix ? ""
    , buildInputs ? [ ]
    , nativeBuildInputs ? [ ]
    , llvmConfigPkg ? clang
    , args ? { }
    }:
    let
      target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] target;
      target_underscores_upper = lib.strings.toUpper target_underscores;
    in
    mkFenixToolchain {
      componentTargets = [ target ];
      defaultCargoBuildTarget = target;
      args =
        # if target == build, we don't need any args, the defaults should work
        lib.optionalAttrs (pkgs.stdenv.buildPlatform.config != target) ({
          # For bindgen, through universal-llvm-config
          "LLVM_CONFIG_PATH_${target_underscores}" = "${llvmConfigPkg}/bin/llvm-config";

          "CC_${target_underscores}" = "${clang}/bin/${binPrefix}clang";
          "CXX_${target_underscores}" = "${clang}/bin/${binPrefix}clang++";
          "AR_${target_underscores}" = "${clang}/bin/${binPrefix}ar";
          "LD_${target_underscores}" = "${clang}/bin/${binPrefix}ld";
          "CARGO_TARGET_${target_underscores_upper}_LINKER" = "${clang}/bin/${binPrefix}clang";
          "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" = "-C link-arg=-fuse-ld=${clang}/bin/${binPrefix}ld -C link-arg=-Wl,--compress-debug-sections=zlib";

          inherit buildInputs nativeBuildInputs;
        } // args);
    };
in
{
  default = mkFenixToolchain (cleanedArgs // {
    toolchain = config.toolchain.default;
  });
  stable = mkFenixToolchain (cleanedArgs // {
    toolchain = config.toolchain.stable;
  });
  nightly = mkFenixToolchain (cleanedArgs // {
    toolchain = config.toolchain.nightly;
  });
  aarch64-linux = mkClangToolchain {
    target = "aarch64-unknown-linux-gnu";
    clang = pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages_14.clang;
    binPrefix = "aarch64-unknown-linux-gnu-";
    llvmConfigPkg = targetLlvmConfigWrapper {
      # seems like it would be better, but it seems to pull in incompatible glibc
      # clangPkg = pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages_14.clang;
      clangPkg = pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages_14.clang-unwrapped;
      libClangPkg = pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages_14.clang-unwrapped.lib;
    };

    args = {
      CFLAGS_aarch64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      CPPFLAGS_aarch64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      CXXFLAGS_aarch64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      BINDGEN_EXTRA_CLANG_ARGS_aarch64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
    };
  };
  x86_64-linux = mkClangToolchain {
    target = "x86_64-unknown-linux-gnu";
    clang = pkgs.pkgsCross.gnu64.buildPackages.llvmPackages_14.clang;
    binPrefix = "x86_64-unknown-linux-gnu-";
    llvmConfigPkg = targetLlvmConfigWrapper {
      # seems like it would be better, but it seems to pull in incompatible glibc
      # clangPkg = pkgs.pkgsCross.gnu32.buildPackages.llvmPackages_14.clang;
      clangPkg = pkgs.pkgsCross.gnu64.buildPackages.llvmPackages_14.clang-unwrapped;
      libClangPkg = pkgs.pkgsCross.gnu64.buildPackages.llvmPackages_14.clang-unwrapped.lib;
    };

    args = {
      CFLAGS_x86_64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu64.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      CPPFLAGS_x86_64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu64.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      CXXFLAGS_x86_64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu64.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      BINDGEN_EXTRA_CLANG_ARGS_x86_64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu64.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
    };
  };
  i686-linux = mkClangToolchain {
    target = "i686-unknown-linux-gnu";
    clang = pkgs.pkgsCross.gnu32.buildPackages.llvmPackages_14.clang;
    binPrefix = "i686-unknown-linux-gnu-";
    llvmConfigPkg = targetLlvmConfigWrapper {
      # seems like it would be better, but it seems to pull in incompatible glibc
      # clangPkg = pkgs.pkgsCross.gnu32.buildPackages.llvmPackages_14.clang;
      clangPkg = pkgs.pkgsCross.gnu32.buildPackages.llvmPackages_14.clang-unwrapped;
      libClangPkg = pkgs.pkgsCross.gnu32.buildPackages.llvmPackages_14.clang-unwrapped.lib;
    };

    args = {
      CFLAGS_i686_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu32.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      CPPFLAGS_i686_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu32.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      CXXFLAGS_i686_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu32.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      BINDGEN_EXTRA_CLANG_ARGS_i686_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu32.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
    };
  };
  # aarch64-darwin = mkFenixToolchain {
  #   componentTargets = [ "aarch64-apple-darwin" ];
  #   defaultCargoBuildTarget = "aarch64-apple-darwin";
  #   args = ({ } // lib.optionalAttrs pkgs.stdenv.isDarwin {
  #     CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER =
  #       let
  #         inherit (pkgs.pkgsCross.aarch64-multiplatform.stdenv) cc;
  #       in
  #       "${cc}/bin/${cc.targetPrefix}cc";
  #   });
  # };
  aarch64-darwin = mkClangToolchain {
    target = "aarch64-apple-darwin";
    clang = pkgs.pkgsCross.aarch64-darwin.buildPackages.llvmPackages_14.clang;
    binPrefix = "aarch64-apple-darwin-";
    llvmConfigPkg = targetLlvmConfigWrapper {
      clangPkg = pkgs.pkgsCross.aarch64-darwin.buildPackages.llvmPackages_14.clang-unwrapped;
      libClangPkg = pkgs.pkgsCross.aarch64-darwin.buildPackages.llvmPackages_14.clang-unwrapped.lib;
    };

    args = {
      CFLAGS_aarch64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.aarch64-darwin.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      CPPFLAGS_aarch64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.aarch64-darwin.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      CXXFLAGS_aarch64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.aarch64-darwin.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      BINDGEN_EXTRA_CLANG_ARGS_aarch64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.aarch64-darwin.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
    };
  };
  x86_64-darwin = mkClangToolchain {
    target = "x86_64-apple-darwin";
    clang = pkgs.pkgsCross.x86_64-darwin.buildPackages.llvmPackages_14.clang;
    binPrefix = "x86_64-apple-darwin-";
    llvmConfigPkg = targetLlvmConfigWrapper {
      clangPkg = pkgs.pkgsCross.x86_64-darwin.buildPackages.llvmPackages_14.clang-unwrapped;
      libClangPkg = pkgs.pkgsCross.x86_64-darwin.buildPackages.llvmPackages_14.clang-unwrapped.lib;
    };

    args = {
      CFLAGS_x86_64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.x86_64-darwin.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      CPPFLAGS_x86_64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.x86_64-darwin.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      CXXFLAGS_x86_64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.x86_64-darwin.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
      BINDGEN_EXTRA_CLANG_ARGS_x86_64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.x86_64-darwin.buildPackages.llvmPackages_14.clang-unwrapped.lib}/lib/clang/14.0.6/include/";
    };
  };

  aarch64-android = mkAndroidToolchain ({
    arch = "aarch64";
    androidVer = 31;
    target = "aarch64-linux-android";
  } // lib.optionalAttrs (args ? androidSdk) (lib.getAttrs [ "androidSdk" ] args));

  arm-android = mkAndroidToolchain ({
    arch = "arm";
    androidVer = 31;
    target = "arm-linux-androideabi";
  } // lib.optionalAttrs (args ? androidSdk) (lib.getAttrs [ "androidSdk" ] args));

  armv7-android = mkAndroidToolchain ({
    arch = "arm";
    androidVer = 31;
    target = "armv7-linux-androideabi";
    androidTarget = "arm-linux-androideabi";
  } // lib.optionalAttrs (args ? androidSdk) (lib.getAttrs [ "androidSdk" ] args));

  x86_64-android = mkAndroidToolchain ({
    arch = "x86_64";
    androidVer = 31;
    target = "x86_64-linux-android";
  } // lib.optionalAttrs (args ? androidSdk) (lib.getAttrs [ "androidSdk" ] args));

  i686-android = mkAndroidToolchain ({
    arch = "i386";
    androidVer = 31;
    target = "i686-linux-android";
  } // lib.optionalAttrs (args ? androidSdk) (lib.getAttrs [ "androidSdk" ] args));

  aarch64-ios = mkIOSToolchain {
    target = "aarch64-apple-ios";
  };
  aarch64-ios-sim = mkIOSToolchain {
    target = "aarch64-apple-ios-sim";
  };
  x86_64-ios = mkIOSToolchain {
    target = "x86_64-apple-ios";
  };

  wasm32-unknown = mkFenixToolchain {
    componentTargets = [ "wasm32-unknown-unknown" ];
    defaultCargoBuildTarget = "wasm32-unknown-unknown";
    args = ({
      CC_wasm32_unknown_unknown = "${pkgs.llvmPackages_15.clang-unwrapped}/bin/clang-15";
      # -Wno-macro-redefined fixes ring building
      CFLAGS_wasm32_unknown_unknown = "-I ${pkgs.llvmPackages_15.libclang.lib}/lib/clang/15.0.7/include/ -Wno-macro-redefined";
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      AR_wasm32_unknown_unknown = "${pkgs.llvmPackages_15.llvm}/bin/llvm-ar";
    });
  };

}

