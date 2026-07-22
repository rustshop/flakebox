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

  dependencyContext = packageSet: {
    packages = {
      nativeBuildInputs = packageSet.pkgsBuildHost;
      buildInputs = packageSet.pkgsHostTarget;
      depsBuildBuild = packageSet.pkgsBuildBuild;
    };
  };

  nativeDependencyContext = dependencyContext pkgs;
  crossDependencyContext = dependencyContext;
  dependencyContextFor =
    packageSet:
    if packageSet.stdenv.hostPlatform.config == pkgs.stdenv.buildPlatform.config then
      nativeDependencyContext
    else
      crossDependencyContext packageSet;
  unsupportedTargetDependencyContext = cellKind: {
    packages.depsBuildBuild = pkgs.pkgsBuildBuild;
    unavailablePackages = {
      nativeBuildInputs = "this ${cellKind} cell has no truthful Nixpkgs package scope for build-host tools targeting the Cargo target";
      buildInputs = "this ${cellKind} cell has no truthful target Nixpkgs package universe";
    };
  };
  mkFenixToolchainWithContext =
    dependencyContext: toolchainArgs:
    mkFenixToolchain toolchainArgs
    // {
      inherit dependencyContext;
    };
in
{
  default = mkFenixToolchainWithContext nativeDependencyContext (
    args
    // {
      targets = {
        default = stdTargets.default;
      };
    }
  );

  nightly = mkFenixToolchainWithContext nativeDependencyContext (
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
  aarch64-linux =
    mkFenixToolchainWithContext (dependencyContextFor pkgs.pkgsCross.aarch64-multiplatform)
      (
        args
        // {
          defaultTarget = "aarch64-unknown-linux-gnu";
          targets = {
            default = stdTargets.aarch64-linux;
          };
        }
      );
  x86_64-linux = mkFenixToolchainWithContext (dependencyContextFor pkgs.pkgsCross.gnu64) (
    args
    // {
      defaultTarget = "x86_64-unknown-linux-gnu";
      targets = {
        x86_64-linux = stdTargets.x86_64-linux;
      };
    }
  );
  i686-linux = mkFenixToolchainWithContext (dependencyContextFor pkgs.pkgsCross.gnu32) (
    args
    // {
      defaultTarget = "i686-unknown-linux-gnu";
      targets = {
        i686-linux = stdTargets.i686-linux;
      };
    }
  );
  riscv64-linux = mkFenixToolchainWithContext (dependencyContextFor pkgs.pkgsCross.riscv64) (
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

  wasm32-unknown =
    mkFenixToolchainWithContext (unsupportedTargetDependencyContext "wasm32-unknown-unknown")
      (
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

  aarch64-android = mkFenixToolchainWithContext (unsupportedTargetDependencyContext "Android") {
    defaultTarget = "aarch64-linux-android";
    targets = {
      aarch64-android = stdTargets.aarch64-android;
    };
  };
  x86_64-android = mkFenixToolchainWithContext (unsupportedTargetDependencyContext "Android") {
    defaultTarget = "x86_64-linux-android";
    targets = {
      x86_64-android = stdTargets.x86_64-android;
    };
  };
  i686-android = mkFenixToolchainWithContext (unsupportedTargetDependencyContext "Android") {
    defaultTarget = "i686-linux-android";
    targets = {
      i686-android = stdTargets.i686-android;
    };
  };
  armv7-android = mkFenixToolchainWithContext (unsupportedTargetDependencyContext "Android") {
    defaultTarget = "armv7-linux-androideabi";
    targets = {
      armv7-android = stdTargets.armv7-android;
    };
  };

}
// lib.optionalAttrs (pkgs.stdenv.buildPlatform.config == "aarch64-apple-darwin") {
  aarch64-darwin = mkFenixToolchainWithContext (dependencyContextFor pkgs.pkgsCross.aarch64-darwin) (
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
  x86_64-darwin = mkFenixToolchainWithContext (dependencyContextFor pkgs.pkgsCross.x86_64-darwin) (
    args
    // {
      defaultTarget = "x86_64-apple-darwin";
      targets = {
        x86_64-darwin = stdTargets.x86_64-darwin;
      };
    }
  );
}
