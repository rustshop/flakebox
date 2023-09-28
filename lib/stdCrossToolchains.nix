{ pkgs
, mkFenixToolchain
, system
, config
, fenix
}: {
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
    args = {
      CARGO_BUILD_TARGET = "aarch64-unknown-linux-gnu";
      CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER =
        let
          inherit (pkgs.pkgsCross.aarch64-multiplatform.stdenv) cc;
        in
        "${cc}/bin/${cc.targetPrefix}cc";
    };
  };
  x86_64-linux = mkFenixToolchain {
    crossTargets = [ "x86_64-unknown-linux-gnu" ];
    args = {
      CARGO_BUILD_TARGET = "x86_64-unknown-linux-gnu";
      CARGO_TARGET_x86_64_UNKNOWN_LINUX_GNU_LINKER =
        let
          inherit (pkgs.pkgsCross.x86_64-multiplatform.stdenv) cc;
        in
        "${cc}/bin/${cc.targetPrefix}cc";
    };
  };
  i686-linux = mkFenixToolchain {
    crossTargets = [ "i686-unknown-linux-gnu" ];
    args = {
      CARGO_BUILD_TARGET = "i686-unknown-linux-gnu";
      CARGO_TARGET_i686_UNKNOWN_LINUX_GNU_LINKER =
        let
          inherit (pkgs.pkgsCross.i686-multiplatform.stdenv) cc;
        in
        "${cc}/bin/${cc.targetPrefix}cc";
    };
  };
  # NOTE: broken, need to figure out
  # https://stackoverflow.com/questions/4391192/why-do-i-get-cc1plus-error-unrecognized-command-line-option-arch
  aarch64-darwin = mkFenixToolchain {
    crossTargets = [ "aarch64-apple-darwin" ];
    args = {
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
    args = {
      CARGO_BUILD_TARGET = "x86_64-apple-darwin";
      CARGO_TARGET_x86_64_APPLE_DARWIN_LINKER =
        let
          inherit (pkgs.pkgsCross.x86_64-multiplatform.stdenv) cc;
        in
        "${cc}/bin/${cc.targetPrefix}cc";
    };
  };
}
