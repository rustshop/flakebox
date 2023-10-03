{ pkgs, flakeboxLib }:
let
  inherit (pkgs) lib;

  rootDir = builtins.path {
    name = "workspace-sanity";
    path = ./.;
  };

  # paths needed to build Rust code
  buildDirs = [
    "Cargo.toml"
    "Cargo.lock"
    ".cargo"
    "bin"
    "lib"
  ];

  # paths needed to run some integration/e2e tests
  testDirs = buildDirs ++ [
    "scripts"
  ];

  multiOutput =
    (flakeboxLib.craneMultiBuild { })
      (craneLib':
        let
          src = flakeboxLib.filter.filterSubdirs {
            root = rootDir;
            dirs = buildDirs;
          };

          craneLib = (craneLib'.overrideArgs {
            pname = "workspace-cross-compile";
            version = "0.0.1";
            inherit src;

            buildInputs = [
              pkgs.openssl
            ];

            nativeBuildInputs = [
              pkgs.pkg-config
            ];
          }).overrideArgsDepsOnly {
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
          bin = craneLib.buildPackage { };
          lib = craneLib.buildPackageGroup {
            packages = [ "workspace-lib" ];
          };

          workspace-sanity-test = craneLib.buildCommand {
            cargoArtifacts = workspaceBuild;
            cmd = ''
              patchShebangs ./scripts/
              ./scripts/e2e-tests.sh
            '';

            src = flakeboxLib.filter.filterSubdirs {
              root = rootDir;
              dirs = testDirs;
            };
          };
        });
in
pkgs.linkFarmFromDrvs "workspace-sanity" (lib.optionals (!pkgs.stdenv.isDarwin) [
  multiOutput.aarch64-android.dev.workspaceBuild
  multiOutput.x86_64-android.dev.workspaceBuild
  multiOutput.i686-android.dev.workspaceBuild
  multiOutput.armv7-android.dev.workspaceBuild
  multiOutput.nightly.dev.workspaceBuild
  multiOutput.dev.workspaceBuild
])
