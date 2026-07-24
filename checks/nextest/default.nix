{ pkgs, flakeboxLib }:
let
  rootDir = ./.;

  buildPaths = [
    "Cargo.toml"
    "Cargo.lock"
    "crate"
  ];

  multiOutput = (flakeboxLib.craneMultiBuild { }) (
    craneLib':
    let
      src = flakeboxLib.source.fromPaths {
        root = rootDir;
        paths = buildPaths;
      };

      craneLib = craneLib'.overrideArgs {
        pname = "nextest-check";
        version = "0.0.1";
        inherit src;
      };
    in
    {
      workspaceDeps = craneLib.buildWorkspaceDepsOnly { };
      nextest = craneLib.cargoNextest {
        cargoArtifacts = craneLib.buildWorkspaceDepsOnly { };
      };
    }
  );
  defaultDevShell = flakeboxLib.mkDevShell { };
  verboseDevShell = flakeboxLib.mkDevShell {
    NEXTEST_SHOW_PROGRESS = "bar";
    NEXTEST_STATUS_LEVEL = "all";
  };
in
assert pkgs.lib.assertMsg (
  !(multiOutput.ci.nextest ? NEXTEST_FINAL_STATUS_LEVEL)
) "cargoNextest leaves final status reporting at nextest's default";
assert pkgs.lib.assertMsg (
  multiOutput.ci.nextest.NEXTEST_SHOW_PROGRESS == "none"
) "cargoNextest hides progress output by default";
assert pkgs.lib.assertMsg (
  multiOutput.ci.nextest.NEXTEST_STATUS_LEVEL == "none"
) "cargoNextest suppresses successful test statuses by default";
assert pkgs.lib.assertMsg (
  !(defaultDevShell ? NEXTEST_FINAL_STATUS_LEVEL)
) "development shells leave final nextest status reporting at its default";
assert pkgs.lib.assertMsg (
  defaultDevShell.NEXTEST_SHOW_PROGRESS == "none"
) "development shells hide nextest progress by default";
assert pkgs.lib.assertMsg (
  defaultDevShell.NEXTEST_STATUS_LEVEL == "none"
) "development shells suppress successful nextest statuses by default";
assert pkgs.lib.assertMsg (
  verboseDevShell.NEXTEST_SHOW_PROGRESS == "bar"
) "development shells allow overriding nextest progress";
assert pkgs.lib.assertMsg (
  verboseDevShell.NEXTEST_STATUS_LEVEL == "all"
) "development shells allow overriding the nextest status level";
pkgs.linkFarmFromDrvs "nextest" [
  multiOutput.ci.nextest
]
