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
  extraRustFlags ? ""
, ...
}@args:
let
  cleanedArgs =
    (removeAttrs args [ "androidSdk" ]) // {
      inherit extraRustFlags;
    };

  mkClangToolchain =
    { target
    , clang
    , binPrefix ? ""
    , buildInputs ? [ ]
    , nativeBuildInputs ? [ ]
    , llvmConfigPkg ? clang
    , args ? { }
    , ...
    }:
    let
      target_underscores = lib.strings.replaceStrings [ "-" ] [ "_" ] target;
      target_underscores_upper = lib.strings.toUpper target_underscores;
    in
    mkFenixToolchain {
      componentTargets = [ target ];
      defaultCargoBuildTarget = target;
      inherit extraRustFlags target;
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
          "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" = "-C link-arg=-fuse-ld=${clang}/bin/${binPrefix}ld -C link-arg=-Wl,--compress-debug-sections=zlib ${extraRustFlags}";

          inherit buildInputs nativeBuildInputs;
        } // args);
    };
in
({
  default = mkFenixToolchain (cleanedArgs // {
    toolchain = config.toolchain.default;
  });
  stable = mkFenixToolchain (cleanedArgs // {
    toolchain = config.toolchain.stable;
  });
  nightly = mkFenixToolchain (cleanedArgs // {
    toolchain = config.toolchain.nightly;
  });
  aarch64-linux = mkClangToolchain (cleanedArgs // {
    target = "aarch64-unknown-linux-gnu";
    clang = pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages.clang;
    binPrefix = "aarch64-unknown-linux-gnu-";
    llvmConfigPkg = targetLlvmConfigWrapper {
      # seems like it would be better, but it seems to pull in incompatible glibc
      # clangPkg = pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages.clang;
      clangPkg = pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages.clang-unwrapped;
      libClangPkg = pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages.clang-unwrapped.lib;
    };

    args = {
      CFLAGS_aarch64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      CPPFLAGS_aarch64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      CXXFLAGS_aarch64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      BINDGEN_EXTRA_CLANG_ARGS_aarch64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.aarch64-multiplatform.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
    };
  });
  x86_64-linux = mkClangToolchain (cleanedArgs // {
    target = "x86_64-unknown-linux-gnu";
    clang = pkgs.pkgsCross.gnu64.buildPackages.llvmPackages.clang;
    binPrefix = "x86_64-unknown-linux-gnu-";
    llvmConfigPkg = targetLlvmConfigWrapper {
      # seems like it would be better, but it seems to pull in incompatible glibc
      # clangPkg = pkgs.pkgsCross.gnu32.buildPackages.llvmPackages.clang;
      clangPkg = pkgs.pkgsCross.gnu64.buildPackages.llvmPackages.clang-unwrapped;
      libClangPkg = pkgs.pkgsCross.gnu64.buildPackages.llvmPackages.clang-unwrapped.lib;
    };

    args = {
      CFLAGS_x86_64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu64.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      CPPFLAGS_x86_64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu64.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      CXXFLAGS_x86_64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu64.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      BINDGEN_EXTRA_CLANG_ARGS_x86_64_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu64.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
    };
  });
  i686-linux = mkClangToolchain (cleanedArgs // {
    target = "i686-unknown-linux-gnu";
    clang = pkgs.pkgsCross.gnu32.buildPackages.llvmPackages.clang;
    binPrefix = "i686-unknown-linux-gnu-";
    llvmConfigPkg = targetLlvmConfigWrapper {
      clangPkg = pkgs.pkgsCross.gnu32.buildPackages.llvmPackages.clang-unwrapped;
      libClangPkg = pkgs.pkgsCross.gnu32.buildPackages.llvmPackages.clang-unwrapped.lib;
    };

    args = {
      CFLAGS_i686_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu32.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      CPPFLAGS_i686_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu32.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      CXXFLAGS_i686_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu32.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      BINDGEN_EXTRA_CLANG_ARGS_i686_unknown_linux_gnu = "-I ${pkgs.pkgsCross.gnu32.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
    };
  });
  wasm32-unknown = mkFenixToolchain (cleanedArgs // {
    target = "wasm32-unknown-unknown";
    componentTargets = [ "wasm32-unknown-unknown" ];
    defaultCargoBuildTarget = "wasm32-unknown-unknown";
    # mold doesn't work for wasm at all
    useMold = false;
    inherit extraRustFlags;
    args = (
      let target_underscores_upper = "WASM32_UNKNOWN_UNKNOWN"; in {
        CC_wasm32_unknown_unknown = "${pkgs.llvmPackages_15.clang-unwrapped}/bin/clang-15";
        # -Wno-macro-redefined fixes ring building
        CFLAGS_wasm32_unknown_unknown = "-I ${pkgs.llvmPackages_15.libclang.lib}/lib/clang/15.0.7/include/ -Wno-macro-redefined";
        # leave these as defaults
        "CARGO_TARGET_${target_underscores_upper}_LINKER" = null;
        "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" = "${extraRustFlags}";
      } // lib.optionalAttrs pkgs.stdenv.isDarwin {
        AR_wasm32_unknown_unknown = "${pkgs.llvmPackages_15.llvm}/bin/llvm-ar";
      }
    );
  });

} // lib.optionalAttrs (pkgs.stdenv.isDarwin) {
  aarch64-darwin = mkClangToolchain (cleanedArgs // {
    target = "aarch64-apple-darwin";
    clang = pkgs.pkgsCross.aarch64-darwin.buildPackages.llvmPackages.clang;
    binPrefix = "aarch64-apple-darwin-";
    llvmConfigPkg = targetLlvmConfigWrapper {
      clangPkg = pkgs.pkgsCross.aarch64-darwin.buildPackages.llvmPackages.clang-unwrapped;
      libClangPkg = pkgs.pkgsCross.aarch64-darwin.buildPackages.llvmPackages.clang-unwrapped.lib;
    };

    args = {
      CFLAGS_aarch64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.aarch64-darwin.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      CPPFLAGS_aarch64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.aarch64-darwin.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      CXXFLAGS_aarch64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.aarch64-darwin.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      BINDGEN_EXTRA_CLANG_ARGS_aarch64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.aarch64-darwin.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
    };
  });
  x86_64-darwin = mkClangToolchain (cleanedArgs // {
    target = "x86_64-apple-darwin";
    clang = pkgs.pkgsCross.x86_64-darwin.buildPackages.llvmPackages.clang;
    binPrefix = "x86_64-apple-darwin-";
    llvmConfigPkg = targetLlvmConfigWrapper {
      clangPkg = pkgs.pkgsCross.x86_64-darwin.buildPackages.llvmPackages.clang-unwrapped;
      libClangPkg = pkgs.pkgsCross.x86_64-darwin.buildPackages.llvmPackages.clang-unwrapped.lib;
    };

    args = {
      CFLAGS_x86_64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.x86_64-darwin.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      CPPFLAGS_x86_64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.x86_64-darwin.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      CXXFLAGS_x86_64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.x86_64-darwin.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      BINDGEN_EXTRA_CLANG_ARGS_x86_64_unknown_darwin_gnu = "-I ${pkgs.pkgsCross.x86_64-darwin.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
    };
  });
} // lib.optionalAttrs (pkgs.stdenv.isDarwin) {
  aarch64-ios = mkIOSToolchain {
    target = "aarch64-apple-ios";
  };
  aarch64-ios-sim = mkIOSToolchain {
    target = "aarch64-apple-ios-sim";
  };
  x86_64-ios = mkIOSToolchain {
    target = "x86_64-apple-ios";
  };
} // lib.optionalAttrs ((args ? androidSdk) || (builtins.hasAttr system android-nixpkgs.sdk)) {
  aarch64-android = mkAndroidToolchain (args // {
    arch = "aarch64";
    androidVer = 31;
    target = "aarch64-linux-android";
  });

  arm-android = mkAndroidToolchain (args // {
    arch = "arm";
    androidVer = 31;
    target = "arm-linux-androideabi";
  });

  armv7-android = mkAndroidToolchain (args // {
    arch = "arm";
    androidVer = 31;
    target = "armv7-linux-androideabi";
    androidTarget = "arm-linux-androideabi";
  });

  x86_64-android = mkAndroidToolchain (args // {
    arch = "x86_64";
    androidVer = 31;
    target = "x86_64-linux-android";
  });

  i686-android = mkAndroidToolchain (args // {
    arch = "i386";
    androidVer = 31;
    target = "i686-linux-android";
  });
})

