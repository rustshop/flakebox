{ pkgs, flakeboxLib }:
let
  inherit (pkgs) lib;

  rootDir = builtins.path {
    name = "workspace-sanity";
    path = ./.;
  };

  # paths needed to build Rust code
  buildPaths = [
    "Cargo.toml"
    "Cargo.lock"
    ".cargo"
    "bin"
    "lib"
  ];

  # paths needed to run some integration/e2e tests
  testPaths = buildPaths ++ [
    "scripts"
  ];

  multiOutput = (flakeboxLib.craneMultiBuild { }) (
    craneLib':
    let
      src = flakeboxLib.filterSubPaths {
        root = rootDir;
        paths = buildPaths;
      };

      craneLib =
        (craneLib'.overrideArgs {
          pname = "workspace-sanity";
          version = "0.0.1";
          buildInputs = [
            pkgs.openssl
          ];

          nativeBuildInputs = [
            pkgs.pkg-config
          ];

          inherit src;

        }).overrideArgsDepsOnly
          {
            cargoVendorDir = craneLib'.vendorCargoDeps {
              inherit src;
            };
            # copy over the linker/ar wrapper scripts which by default would get
            # stripped by crane
            dummySrc = craneLib'.mkDummySrc {
              inherit src;
              extraDummyScript = ''
                # not actually needed anymore, but just trying `overrideArgsDepsOnly`
                # # temporary workaround: https://github.com/ipetkov/crane/issues/312#issuecomment-1601827484
                # # rm -f $(find $out | grep bin/crane-dummy/main.rs)
                true
              '';
            };
          };
    in
    rec {
      workspaceDeps = craneLib.buildWorkspaceDepsOnly { };
      workspaceBuild = craneLib.buildWorkspace {
        cargoArtifacts = workspaceDeps;
      };
      workspace-sanity = craneLib.buildPackage { };
      workspace-sanity-lib = craneLib.buildPackageGroup {
        packages = [ "workspace-sanity-lib" ];
      };

      workspace-sanity-test = craneLib.buildCommand {
        cargoArtifacts = workspaceBuild;
        cmd = ''
          patchShebangs ./scripts/
          ./scripts/e2e-tests.sh
        '';

        src = flakeboxLib.filterSubPaths {
          root = rootDir;
          paths = testPaths;
        };
      };
    }
  );
in
pkgs.linkFarmFromDrvs "workspace-sanity" [
  multiOutput.ci.workspaceBuild
  multiOutput.ci.workspace-sanity
  multiOutput.ci.workspace-sanity-lib
  multiOutput.ci.workspace-sanity-test
]
