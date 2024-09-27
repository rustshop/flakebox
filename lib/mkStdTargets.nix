{
  pkgs,
  system,
  config,
  fenix,
  lib,
  mkAndroidTarget,
  mkIOSTarget,
  targetLlvmConfigWrapper,
  mkClangTarget,
  mkNativeTarget,
  mkTarget,
  android-nixpkgs,
}:
{ ... }@mkStdTargetsArgs:
{
  default = mkNativeTarget { };

}
// lib.optionalAttrs pkgs.stdenv.isLinux {
  aarch64-linux = mkClangTarget {
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
  };

  x86_64-linux = mkClangTarget {
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
  };

  i686-linux = mkClangTarget {
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
  };

  riscv64-linux = mkClangTarget {
    target = "riscv64gc-unknown-linux-gnu";
    clang = pkgs.pkgsCross.riscv64.buildPackages.llvmPackages.clang;
    binPrefix = "riscv64-unknown-linux-gnu-";
    llvmConfigPkg = targetLlvmConfigWrapper {
      clangPkg = pkgs.pkgsCross.riscv64.buildPackages.llvmPackages.clang-unwrapped;
      libClangPkg = pkgs.pkgsCross.riscv64.buildPackages.llvmPackages.clang-unwrapped.lib;
    };

    args = {
      CFLAGS_riscv64gc_unknown_linux_gnu = "-I ${pkgs.pkgsCross.riscv64.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      CPPFLAGS_riscv64gc_unknown_linux_gnu = "-I ${pkgs.pkgsCross.riscv64.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      CXXFLAGS_riscv64gc_unknown_linux_gnu = "-I ${pkgs.pkgsCross.riscv64.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
      BINDGEN_EXTRA_CLANG_ARGS_riscv64gc_unknown_linux_gnu = "-I ${pkgs.pkgsCross.riscv64.buildPackages.llvmPackages.clang-unwrapped.lib}/lib/clang/16/include/";
    };
  };
}
// {
  wasm32-unknown =
    { extraRustFlags, ... }@args:
    mkTarget {
      target = "wasm32-unknown-unknown";
      # mold doesn't work for wasm at all
      canUseMold = false;
      args = (
        let
          target_underscores_upper = "WASM32_UNKNOWN_UNKNOWN";
        in
        {
          CC_wasm32_unknown_unknown = "${pkgs.llvmPackages_15.clang-unwrapped}/bin/clang-15";
          # -Wno-macro-redefined fixes ring building
          CFLAGS_wasm32_unknown_unknown = "-I ${pkgs.llvmPackages_15.libclang.lib}/lib/clang/15.0.7/include/ -Wno-macro-redefined";
          # leave these as defaults
          "CARGO_TARGET_${target_underscores_upper}_LINKER" = null;
          "CARGO_TARGET_${target_underscores_upper}_RUSTFLAGS" = "${extraRustFlags}";
        }
        // lib.optionalAttrs pkgs.stdenv.isDarwin {
          AR_wasm32_unknown_unknown = "${pkgs.llvmPackages_15.llvm}/bin/llvm-ar";
        }
      );
    } args;
}
//
  lib.optionalAttrs ((mkStdTargetsArgs ? androidSdk) || (builtins.hasAttr system android-nixpkgs.sdk))
    {
      aarch64-android = mkAndroidTarget {
        arch = "aarch64";
        androidVer = 31;
        target = "aarch64-linux-android";
      };

      arm-android = mkAndroidTarget {
        arch = "arm";
        androidVer = 31;
        target = "arm-linux-androideabi";
      };

      armv7-android = mkAndroidTarget {
        arch = "arm";
        androidVer = 31;
        target = "armv7-linux-androideabi";
        androidTarget = "arm-linux-androideabi";
      };

      x86_64-android = mkAndroidTarget {
        arch = "x86_64";
        androidVer = 31;
        target = "x86_64-linux-android";
      };

      i686-android = mkAndroidTarget {
        arch = "i386";
        androidVer = 31;
        target = "i686-linux-android";
      };

    }
// lib.optionalAttrs (pkgs.stdenv.buildPlatform.config == "aarch64-apple-darwin") {
  aarch64-darwin = mkClangTarget {
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
  };

}
// lib.optionalAttrs (pkgs.stdenv.buildPlatform.config == "x86_64-apple-darwin") {
  x86_64-darwin = mkClangTarget {
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
  };
}
// lib.optionalAttrs (pkgs.stdenv.isDarwin) {
  aarch64-ios = mkIOSTarget ({
    target = "aarch64-apple-ios";
  });
  aarch64-ios-sim = mkIOSTarget ({
    target = "aarch64-apple-ios-sim";
  });
  x86_64-ios = mkIOSTarget ({
    target = "x86_64-apple-ios";
  });
}
