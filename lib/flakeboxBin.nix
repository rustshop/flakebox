{ filterSubPaths
, craneLib
, craneMultiBuild
}:
let
  src = filterSubPaths {
    root = builtins.path {
      name = "flakebox";
      path = ../.;
    };
    paths = [
      "Cargo.toml"
      "Cargo.lock"
      ".cargo"
      "flakebox-bin"
    ];
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
