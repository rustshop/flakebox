{ pkgs, flakeboxLib }:
let

  toolchainArgs = {
    stdenv = pkgs.clang18Stdenv;
    clang = pkgs.llvmPackages_18.clang;
    libclang = pkgs.llvmPackages_18.libclang.lib;
    clang-unwrapped = pkgs.llvmPackages_18.clang-unwrapped;
  };

  toolchainsStd = flakeboxLib.mkStdFenixToolchains toolchainArgs;

  multiOutput =
    (flakeboxLib.craneMultiBuild {
      toolchains = toolchainsStd;
    })
      (
        craneLib':
        let
          target_underscores_upper = pkgs.stdenv.buildPlatform.rust.cargoEnvVarTarget;
        in
        {
          checkStdenv = craneLib'.mkCargoDerivation {
            pname = "check-stdenv";
            version = "0.0.1";
            cargoArtifacts = null;
            cargoVendorDir = null;
            doInstallCargoArtifacts = false;
            src = ./.;
            buildPhaseCargoCommand = ''
              set -x
              if [[ "$(${pkgs.which}/bin/which cc)" != *clang-wrapper-18* ]]; then
                set +x
                exit 1
              fi
              if [[ "$CARGO_TARGET_${target_underscores_upper}_LINKER" != *clang-wrapper-18* ]]; then
                set +x
                exit 1
              fi
              set +x
            '';
            doCheck = false;
          };
        }
      );
in
pkgs.linkFarmFromDrvs "custom-stdenv" [
  multiOutput.ci.checkStdenv
]
