{ pkgs, flakeboxLib }:
let

  llvmPackages = if pkgs.stdenv.isDarwin then pkgs.llvmPackages else pkgs.llvmPackages_18;
  clangMajor = pkgs.lib.versions.major llvmPackages.clang.version;

  toolchainArgs = {
    stdenv = p: llvmPackages.stdenv;
    clang = llvmPackages.clang;
    libclang = llvmPackages.libclang.lib;
    clang-unwrapped = llvmPackages.clang-unwrapped;
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
            src = flakeboxLib.source.fromFileset {
              root = ./.;
              fileset = ./default.nix;
              filter = flakeboxLib.source.filters.excludeDirectoriesNamed [ "specs" ];
            };
            buildPhaseCargoCommand = ''
              set -x
              if [[ "$(${pkgs.which}/bin/which cc)" != *clang-wrapper-${clangMajor}* ]]; then
                set +x
                exit 1
              fi
              if [[ "$CARGO_TARGET_${target_underscores_upper}_LINKER" != *clang-wrapper-${clangMajor}* ]]; then
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
