{ pkgs, flakeboxLib }:
let
  rootDir = builtins.path {
    name = "nextest";
    path = ./.;
  };

  buildPaths = [
    "Cargo.toml"
    "Cargo.lock"
    "crate"
  ];

  multiOutput = (flakeboxLib.craneMultiBuild { }) (
    craneLib':
    let
      src = flakeboxLib.filterSubPaths {
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
in
pkgs.linkFarmFromDrvs "nextest" [
  multiOutput.ci.nextest
]
