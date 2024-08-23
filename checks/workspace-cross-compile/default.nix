{ pkgs, flakeboxLib, full }:
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

  buildInputs = pkgs: [
    pkgs.openssl
  ];
  
  nativeBuildInputs = pkgs: [
    pkgs.pkgsBuildTarget.pkg-config
  ];

  multiOutput =
    (flakeboxLib.craneMultiBuild { inherit buildInputs; inherit nativeBuildInputs; })
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
          bin = craneLib.buildPackageGroup {
            packages = [ "workspace-bin" ];
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
pkgs.linkFarmFromDrvs "workspace-non-rust" (

  # if Android is supported, test at leasat one cross-compilation target to android
  lib.optionals (multiOutput ? aarch64-android) [
    # rocksdb only on aarch64, most probably work on other ones
    multiOutput.aarch64-android.ci.workspaceBuild
  ] ++
  # on Linux test all android cross-compilation
  lib.optionals (pkgs.system == "x86_64-linux") [
    # openssl & others, try on android
    multiOutput.x86_64-android.ci.lib
    multiOutput.i686-android.ci.lib
    multiOutput.armv7-android.ci.lib
    # even with newer llvm14, rocksdb doesn't compile on x86_64-darwin,
    # it might get fixed at some point (newer llvm or librocksdb-sys)

  ] ++
  # test native build on every platform, except x86 macos, where
  # it's broken for some reason
  lib.optionals (pkgs.system != "x86_64-darwin") [
    multiOutput.ci.workspaceBuild
  ] ++
  # in full mode test cross-compilation to Linux targets
  lib.optionals full [
    # double check nightly
    multiOutput.nightly.ci.workspaceBuild
  ] ++
  lib.optionals (full && pkgs.stdenv.isLinux) [
    multiOutput.aarch64-linux.ci.workspaceBuild
    multiOutput.aarch64-linux-musl.ci.workspaceBuild
    multiOutput.x86_64-linux.ci.workspaceBuild
    multiOutput.x86_64-linux-musl.ci.workspaceBuild
    multiOutput.i686-linux.ci.workspaceBuild
    multiOutput.i686-linux-musl.ci.workspaceBuild
    multiOutput.riscv64-linux.ci.workspaceBuild
    multiOutput.mingw64.ci.workspaceBuild
  ] ++
    # in full mode, when supported, test all android targets
  lib.optionals (full && multiOutput ? aarch64-android) [
    multiOutput.aarch64-android.ci.workspaceBuild
    multiOutput.x86_64-android.ci.workspaceBuild
    multiOutput.i686-android.ci.workspaceBuild
    multiOutput.armv7-android.ci.workspaceBuild
  ]
)
