{ pkgs
, mkFenixToolchain
, system
, config
, fenix
, lib
}:

{
  # this needs to be a function just to avoid some extra stuff in the result
  # though in the future, we could use it to parametrize what's being returned
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
}
