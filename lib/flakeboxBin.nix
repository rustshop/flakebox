{ lib
, pkgs
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
  version = "0.0.1";

  cargoSha256 = "sha256-e39iCbrxI24B9usf+XQwTs/n7UIgg0s1hXFWmLajnMg=";
}
