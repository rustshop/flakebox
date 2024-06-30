{ mkStdTargets
, mkFenixToolchain
, lib
, pkgs
, system
, fenix
, android-nixpkgs
, defaultClang
, defaultLibClang
, defaultClangUnwrapped
, defaultStdenv
}:
{ clang ? defaultClang
, libclang ? defaultLibClang
, clang-unwrapped ? defaultClangUnwrapped
, stdenv ? defaultStdenv
, buildInputs ? pkgs: []
, nativeBuildInputs ? pkgs: []
, ...
}@oldArgs:
let
stdTargets = mkStdTargets { };
args = removeAttrs oldArgs [ "buildInputs" "nativeBuildInputs" ];
in
{
  default = mkFenixToolchain (args // {
    targets = {
      default = stdTargets.default;
    };
    craneArgs = {
        buildInputs = buildInputs pkgs;
        nativeBuildInputs = nativeBuildInputs pkgs;
    };
  });

  nightly = mkFenixToolchain (args // {
    targets = {
      default = stdTargets.default;
    };
    channel = "complete";
    craneArgs = {
        buildInputs = buildInputs pkgs;
        nativeBuildInputs = nativeBuildInputs pkgs;
    };
  });

} // lib.optionalAttrs pkgs.stdenv.isLinux {
  aarch64-linux = mkFenixToolchain (args // {
    defaultTarget = "aarch64-unknown-linux-gnu";
    targets = {
      default = stdTargets.aarch64-linux;
    };
    craneArgs = {
        buildInputs = buildInputs pkgs.pkgsCross.aarch64-multiplatform;
        nativeBuildInputs = nativeBuildInputs pkgs.pkgsCross.aarch64-multiplatform;
    };
  });
  aarch64-linux-musl = mkFenixToolchain (args // {
    defaultTarget = "aarch64-unknown-linux-musl";
    targets = {
      default = stdTargets.aarch64-linux-musl;
    };
    craneArgs = {
        buildInputs = buildInputs pkgs.pkgsCross.aarch64-multiplatform-musl;
        nativeBuildInputs = nativeBuildInputs pkgs.pkgsCross.aarch64-multiplatform-musl;
    };
  });
  x86_64-linux = mkFenixToolchain (args // {
    defaultTarget = "x86_64-unknown-linux-gnu";
    targets = {
      x86_64-linux = stdTargets.x86_64-linux;
    };
    craneArgs = {
        buildInputs = buildInputs pkgs.pkgsCross.gnu64;
        nativeBuildInputs = nativeBuildInputs pkgs.pkgsCross.gnu64;
    };
  });
  x86_64-linux-musl = mkFenixToolchain (args // {
    defaultTarget = "x86_64-unknown-linux-musl";
    targets = {
      x86_64-linux-musl = stdTargets.x86_64-linux-musl;
    };
    craneArgs = {
        buildInputs = buildInputs pkgs.pkgsCross.musl64;
        nativeBuildInputs = nativeBuildInputs pkgs.pkgsCross.musl64;
    };
  });
  i686-linux = mkFenixToolchain (args // {
    defaultTarget = "i686-unknown-linux-gnu";
    targets = {
      i686-linux = stdTargets.i686-linux;
    };
    craneArgs = {
        buildInputs = buildInputs pkgs.pkgsCross.gnu32;
        nativeBuildInputs = nativeBuildInputs pkgs.pkgsCross.gnu32;
    };
  });
  i686-linux-musl = mkFenixToolchain (args // {
    defaultTarget = "i686-unknown-linux-musl";
    targets = {
      i686-linux = stdTargets.i686-linux-musl;
    };
    craneArgs = {
        buildInputs = buildInputs pkgs.pkgsCross.musl32;
        nativeBuildInputs = nativeBuildInputs pkgs.pkgsCross.musl32;
    };
  });
  riscv64-linux = mkFenixToolchain (args // {
    defaultTarget = "riscv64gc-unknown-linux-gnu";
    targets = {
      riscv64-linux = stdTargets.riscv64-linux;
    };
    craneArgs = {
        buildInputs = buildInputs pkgs.pkgsCross.riscv64;
        nativeBuildInputs = nativeBuildInputs pkgs.pkgsCross.riscv64;
    };
  });
} // {

  wasm32-unknown = mkFenixToolchain (args // {
    defaultTarget = "wasm32-unknown-unknown";
    targets = {
      wasm32-unknown = stdTargets.wasm32-unknown;
    };
    craneArgs = {
        buildInputs = buildInputs pkgs.pkgsCross.wasi32;
        nativeBuildInputs = nativeBuildInputs pkgs.pkgsCross.wasi32;
    };
  });

} // lib.optionalAttrs ((args ? androidSdk) || (builtins.hasAttr system android-nixpkgs.sdk)) {

  aarch64-android = mkFenixToolchain {
    defaultTarget = "aarch64-linux-android";
    targets = {
      aarch64-android = stdTargets.aarch64-android;
    };
    craneArgs = {
        buildInputs = buildInputs pkgs.pkgsCross.aarch64-android-prebuilt;
        nativeBuildInputs = nativeBuildInputs pkgs.pkgsCross.aarch64-android-prebuilt;
    };
  };
  x86_64-android = mkFenixToolchain {
    defaultTarget = "x86_64-linux-android";
    targets = {
      x86_64-android = stdTargets.x86_64-android;
    };
    # no crossPkgs available
    craneArgs = {};
  };
  i686-android = mkFenixToolchain {
    defaultTarget = "i686-linux-android";
    targets = {
      i686-android = stdTargets.i686-android;
    };
    # no crossPkgs available
    craneArgs = {};
  };
  armv7-android = mkFenixToolchain {
    defaultTarget = "armv7-linux-androideabi";
    targets = {
      armv7-android = stdTargets.armv7-android;
    };
    craneArgs = {
        buildInputs = buildInputs pkgs.pkgsCross.armv7-android-prebuilt;
        nativeBuildInputs = nativeBuildInputs pkgs.pkgsCross.armv7-android-prebuilt;
    };
  };

} // lib.optionalAttrs (pkgs.stdenv.buildPlatform.config == "aarch64-apple-darwin") {
  aarch64-darwin = mkFenixToolchain (args // {
    defaultTarget = "aarch64-apple-darwin";
    targets = {
      aarch64-darwin = stdTargets.aarch64-darwin;
    };
    # cross compilation is broken for apple-darwin
    craneArgs = {};
  });

} // lib.optionalAttrs (pkgs.stdenv.buildPlatform.config == "x86_64-apple-darwin") {
  x86_64-darwin = mkFenixToolchain (args // {
    defaultTarget = "x86_64-apple-darwin";
    targets = {
      x86_64-darwin = stdTargets.x86_64-darwin;
    };
    # cross compilation is broken for apple-darwin
    craneArgs = {};
  });
}
