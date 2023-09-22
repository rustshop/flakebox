{
  description = "Toolkit for building Nix Flake development environments for Rust projects";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";

    crane = {
      url = "github:dpc/crane?rev=afdf9ab92ed2880c4e39aba5106677e3385717f4";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, flake-utils, crane, fenix }:

    let
      mkLib = pkgs: import ./lib
        {
          inherit pkgs crane fenix;
        };
    in
    { } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        flakeboxLib = mkLib pkgs { };
      in
      {
        lib = mkLib pkgs;

        packages = {
          bootstrap = pkgs.writeShellScriptBin "flakebox-bootstrap" "exec ${pkgs.bash}/bin/bash ${./bin/bootstrap.sh} ${./bin/bootstrap.flake.nix} \"$@\"";
          share = flakeboxLib.share;
          default = flakeboxLib.flakeboxBin;
          docs = flakeboxLib.docs;
        };

        devShells = {
          default = flakeboxLib.mkDevShell {
            packages = [ pkgs.mold pkgs.mdbook ];
          };
        };
      });
}
