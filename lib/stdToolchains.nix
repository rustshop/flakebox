{ pkgs
, mkFenixToolchain
, system
, config
, fenix
}:
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
    crossTargets = [ "aarch64-unknown-linux-gnu" ];
    args = prev: {
      CARGO_BUILD_TARGET = "aarch64-unknown-linux-gnu";

      CC_aarch64-unknown-linux-gnu = "aarch64-unknown-linux-gnu-clang";
      CXX_aarch64-unknown-linux-gnu = "aarch64-unknown-linux-gnu-clang++";
      AR_aarch64-unknown-linux-gnu = "aarch64-unknown-linux-gnu-clang";
      LD_aarch64-unknown-linux-gnu = "aarch64-unknown-linux-gnu-lld";
      CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "aarch64-unknown-linux-gnu-clang";
      CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS = "-C link-arg=-Wl,--compress-debug-sections=zlib -C link-arg=-fuse-ld=mold";

      buildInputs = prev.buildInputs or [ ] ++ [
        pkgs.pkgsCross.aarch64-multiplatform.clangStdenv.cc
        pkgs.pkgsCross.aarch64-multiplatform.libgcc
      ];
    };
  };
  x86_64-linux = mkFenixToolchain {
    crossTargets = [ "x86_64-unknown-linux-gnu" ];
    args = prev: ({
      CARGO_BUILD_TARGET = "x86_64-unknown-linux-gnu";

      CC_x86_64-unknown-linux-gnu = "x86_64-unknown-linux-gnu-clang";
      CXX_x86_64-unknown-linux-gnu = "x86_64-unknown-linux-gnu-clang++";
      AR_x86_64-unknown-linux-gnu = "x86_64-unknown-linux-gnu-clang";
      LD_x86_64-unknown-linux-gnu = "x86_64-unknown-linux-gnu-lld";
      CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER = "x86_64-unknown-linux-gnu-clang";
      CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUSTFLAGS = "-C link-arg=-Wl,--compress-debug-sections=zlib -C link-arg=-fuse-ld=mold";

      buildInputs = prev.buildInputs or [ ] ++ [
        pkgs.pkgsCross.gnu64.clangStdenv.cc
        pkgs.pkgsCross.gnu64.libgcc
      ];
    });
  };
  i686-linux = mkFenixToolchain {
    crossTargets = [ "i686-unknown-linux-gnu" ];
    args = prev: {
      CARGO_BUILD_TARGET = "i686-unknown-linux-gnu";

      CC_i686-unknown-linux-gnu = "i686-unknown-linux-gnu-clang";
      CXX_i686-unknown-linux-gnu = "i686-unknown-linux-gnu-clang++";
      AR_i686-unknown-linux-gnu = "i686-unknown-linux-gnu-clang";
      LD_i686-unknown-linux-gnu = "i686-unknown-linux-gnu-lld";
      CARGO_TARGET_I686_UNKNOWN_LINUX_GNU_LINKER = "i686-unknown-linux-gnu-clang";
      CARGO_TARGET_I686_UNKNOWN_LINUX_GNU_RUSTFLAGS = "-C link-arg=-Wl,--compress-debug-sections=zlib";

      buildInputs = prev.buildInputs or [ ] ++ [
        pkgs.pkgsCross.gnu32.clangStdenv.cc
        pkgs.pkgsCross.gnu32.libgcc
      ];
    };
  };
  # NOTE: broken, need to figure out
  # NOTE: probably only works on MacOS
  # https://stackoverflow.com/questions/4391192/why-do-i-get-cc1plus-error-unrecognized-command-line-option-arch
  aarch64-darwin = mkFenixToolchain {
    crossTargets = [ "aarch64-apple-darwin" ];
    args = prev: {

      CARGO_BUILD_TARGET = "aarch64-apple-darwin";
      CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER =
        let
          inherit (pkgs.pkgsCross.aarch64-multiplatform.stdenv) cc;
        in
        "${cc}/bin/${cc.targetPrefix}cc";
    };
  };
  x86_64-darwin = mkFenixToolchain {
    crossTargets = [ "x86_64-apple-darwin" ];
    args = prev: {
      CARGO_BUILD_TARGET = "x86_64-apple-darwin";
      CARGO_TARGET_x86_64_APPLE_DARWIN_LINKER =
        let
          inherit (pkgs.pkgsCross.x86_64-multiplatform.stdenv) cc;
        in
        "${cc}/bin/${cc.targetPrefix}cc";
    };
  };
}
