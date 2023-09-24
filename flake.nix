{
  description = "Toolkit for building Nix Flake development environments for Rust projects";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    crane = {
      url = "github:dpc/crane?rev=60dcbcab46446bb852473a995fb0008d74c8b78d";
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

          overlays = [
            (final: prev: {
              # TODO: switch to mainstream after https://github.com/crate-ci/typos/pull/708 is released
              typos = prev.rustPlatform.buildRustPackage {
                pname = "typos";
                version = "1.16.9-stdin-inputs";

                src = prev.fetchFromGitHub {
                  owner = "dpc";
                  repo = "typos";
                  rev = "04059e022c800ef0e1d6376f3a94923b0b697990";
                  hash = "sha256-5OLq9uevJW1dTGMAkCGx2PyAyemmoiSIJ9DRGiL6gpM=";
                };

                cargoHash = "sha256-wD6D3v6QxMNmULGZY8hSpcXPipzeV00TqyvUgUi4hrI=";
              };
            })
          ];
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
