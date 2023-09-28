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
        craneLib = flakeboxLib.craneLib;
      in
      {
        lib = mkLib pkgs;

        packages = {
          bootstrap = pkgs.writeShellScriptBin "flakebox-bootstrap" "exec ${pkgs.bash}/bin/bash ${./bin/bootstrap.sh} ${./bin/bootstrap.flake.nix} \"$@\"";
          share = flakeboxLib.share;
          default = flakeboxLib.flakeboxBin;
          docs = flakeboxLib.docs;
        };

        legacyPackages =
          let
            src = flakeboxLib.filter.filterSubdirs {
              root = builtins.path {
                name = "flakebox";
                path = ./.;
              };
              dirs = [
                "Cargo.toml"
                "Cargo.lock"
                ".cargo"
                "flakebox-bin"
              ];
            };

            packagesFn = craneLib':
              let
                craneLib = (craneLib'.overrideArgs (prev: {
                  pname = "flexbox";
                  nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [
                    pkgs.mold
                  ];
                  inherit src;
                }));
              in
              rec {
                workspaceDeps = craneLib.buildWorkspaceDepsOnly { };
                workspaceBuild = craneLib.buildWorkspace {
                  cargoArtifacts = workspaceDeps;
                };
                flakebox = craneLib.buildPackage { };
              };
            profilesFn = craneLib: craneLib.mapWithProfiles packagesFn [ "dev" "ci" "release" ];
          in
          (
            (profilesFn craneLib)
            // (flakeboxLib.mapWithToolchains
              (toolchainName: craneLib: profilesFn craneLib)
              flakeboxLib.stdCrossToolchains)
          );

        devShells = {
          default = flakeboxLib.mkDevShell {
            packages = [ pkgs.mold pkgs.mdbook ];
          };
        };
      });
}
