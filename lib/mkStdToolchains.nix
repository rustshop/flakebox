{
  mkStdTargets,
  mkFenixToolchain,
  lib,
  pkgs,
  system,
  fenix,
  android-nixpkgs,
  defaultClang,
  defaultLibClang,
  defaultClangUnwrapped,
  defaultStdenv,
}:
{
  clang ? defaultClang,
  libclang ? defaultLibClang,
  clang-unwrapped ? defaultClangUnwrapped,
  stdenv ? defaultStdenv,
  ...
}@args:
let
  stdTargets = mkStdTargets { };
in
{
  default = mkFenixToolchain (
    args
    // {
      targets = {
        default = stdTargets.default;
      };
    }
  );

  nightly = mkFenixToolchain (
    args
    // {
      targets = {
        default = stdTargets.default;
      };
      channel = "complete";
    }
  );

}
// lib.optionalAttrs pkgs.stdenv.isLinux {
  aarch64-linux = mkFenixToolchain (
    args
    // {
      defaultTarget = "aarch64-unknown-linux-gnu";
      targets = {
        default = stdTargets.aarch64-linux;
      };
    }
  );
  x86_64-linux = mkFenixToolchain (
    args
    // {
      defaultTarget = "x86_64-unknown-linux-gnu";
      targets = {
        x86_64-linux = stdTargets.x86_64-linux;
      };
    }
  );
  i686-linux = mkFenixToolchain (
    args
    // {
      defaultTarget = "i686-unknown-linux-gnu";
      targets = {
        i686-linux = stdTargets.i686-linux;
      };
    }
  );
  riscv64-linux = mkFenixToolchain (
    args
    // {
      defaultTarget = "riscv64gc-unknown-linux-gnu";
      targets = {
        riscv64-linux = stdTargets.riscv64-linux;
      };
    }
  );
}
// {

  wasm32-unknown = mkFenixToolchain (
    args
    // {
      defaultTarget = "wasm32-unknown-unknown";
      targets = {
        wasm32-unknown = stdTargets.wasm32-unknown;
      };
    }
  );

}
// lib.optionalAttrs ((args ? androidSdk) || (builtins.hasAttr system android-nixpkgs.sdk)) {

  aarch64-android = mkFenixToolchain {
    defaultTarget = "aarch64-linux-android";
    targets = {
      aarch64-android = stdTargets.aarch64-android;
    };
  };
  x86_64-android = mkFenixToolchain {
    defaultTarget = "x86_64-linux-android";
    targets = {
      x86_64-android = stdTargets.x86_64-android;
    };
  };
  i686-android = mkFenixToolchain {
    defaultTarget = "i686-linux-android";
    targets = {
      i686-android = stdTargets.i686-android;
    };
  };
  armv7-android = mkFenixToolchain {
    defaultTarget = "armv7-linux-androideabi";
    targets = {
      armv7-android = stdTargets.armv7-android;
    };
  };

}
// lib.optionalAttrs (pkgs.stdenv.buildPlatform.config == "aarch64-apple-darwin") {
  aarch64-darwin = mkFenixToolchain (
    args
    // {
      defaultTarget = "aarch64-apple-darwin";
      targets = {
        aarch64-darwin = stdTargets.aarch64-darwin;
      };
    }
  );

}
// lib.optionalAttrs (pkgs.stdenv.buildPlatform.config == "x86_64-apple-darwin") {
  x86_64-darwin = mkFenixToolchain (
    args
    // {
      defaultTarget = "x86_64-apple-darwin";
      targets = {
        x86_64-darwin = stdTargets.x86_64-darwin;
      };
    }
  );
}
