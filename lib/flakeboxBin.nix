{
  pkgs,
  source,
}:
let
  src = source.fromPaths {
    root = ../.;
    paths = [
      "Cargo.toml"
      "Cargo.lock"
      "flakebox-bin"
    ];
    filter = source.filters.excludeDirectoriesNamed [ "specs" ];
  };
in
pkgs.rustPlatform.buildRustPackage {
  inherit src;

  pname = "flakebox";
  version = "0.1.0";

  cargoHash = "sha256-L0UAVv+JUuADoMH2RiYUCnyOKNMBVMlgz6m0zxOcep4=";
}
