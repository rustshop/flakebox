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
    "rocksdb"
  ];

  # paths needed to run some integration/e2e tests
  testPaths = buildPaths ++ [
    "scripts"
  ];

  multiOutput =
    (flakeboxLib.craneMultiBuild { })
      (craneLib':
        let
          src = flakeboxLib.filterSubPaths {
            root = rootDir;
            paths = buildPaths;
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
          lib = craneLib.buildPackageGroup {
            packages = [ "workspace-lib" ];
          };
          # compiling this stuff is so slow, we do it separately
          lib-rocksdb = craneLib.buildPackageGroup {
            packages = [ "workspace-lib-rocksdb" ];
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
        });
in
pkgs.linkFarmFromDrvs "workspace-sanity" (
  (lib.optionals (!pkgs.stdenv.isDarwin) [
    # rocksdb only on aarch64, most probably work on other ones
    multiOutput.aarch64-android.dev.workspaceBuild
    multiOutput.x86_64-android.dev.lib
    multiOutput.i686-android.dev.lib
    multiOutput.armv7-android.dev.lib
    # even with newer llvm14, rocksdb doesn't compile on x86_64-darwin
  ]) ++ lib.optionals (pkgs.stdenv.isAarch64 || !pkgs.stdenv.isDarwin) [
    # test everything natively as well
    multiOutput.dev.workspaceBuild
  ] ++ [
    multiOutput.nightly.dev.lib
  ]
)
