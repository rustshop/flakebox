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

  cargoSha256 = "sha256-hsHGZAxZube9xpdVp4xxZu6c+9s0mLO1GpZlPIwJ348=";
}
