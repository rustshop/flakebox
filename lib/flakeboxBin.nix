{
  lib,
  pkgs,
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
pkgs.rustPlatform.buildRustPackage {
  inherit src;

  pname = "flakebox";
  version = "0.1.0";

  cargoHash = "sha256-L0UAVv+JUuADoMH2RiYUCnyOKNMBVMlgz6m0zxOcep4=";
  useFetchCargoVendor = true;
}
