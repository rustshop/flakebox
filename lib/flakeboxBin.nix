{ craneLib
, craneMultiBuild
, lib
}:
let
  fs = lib.fileset;
  fileSet = fs.unions [
    ../Cargo.toml
    ../Cargo.lock
    ../flakebox-bin
  ];
  src = fs.toSource {
    root = ../.;
    fileset = fileSet;
  };
in
(
  (craneMultiBuild { }) (craneLib':
    let
      craneLib = (craneLib'.overrideArgs {
        pname = "flexbox";

        doCheck = false;

        installCargoArtifactsMode = "use-zstd";

        nativeBuildInputs = [ ];
        inherit src;
      });
    in
    rec {

      deps =
        craneLib.buildDepsOnly { };

      bin = craneLib.buildPackage {
        cargoArtifacts = deps;
      };
    })).bin
