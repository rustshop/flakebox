{
  description = "Toolkit for building Nix Flake development environments for Rust projects";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    crane = {
      url = "github:dpc/crane?rev=bf5f4b71b446e5784900ee9ae0f2569e5250e360";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    android-nixpkgs = {
      url = "github:dpc/android-nixpkgs?rev=2e42268a196375ce9b010a10ec5250d2f91a09b4"; # stable channel https://github.com/tadfisher/android-nixpkgs/tree/stable
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, crane, fenix, android-nixpkgs }:

    let
      mkLib = pkgs: import ./lib
        {
          inherit pkgs crane fenix android-nixpkgs nixpkgs;
        };
    in
    { } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
        };
        pkgs = import nixpkgs {
          inherit system;

          overlays = [
            (final: prev: {
              rblake2sum = pkgs-unstable.rblake2sum;

              # TODO: switch to mainstream after https://github.com/crate-ci/typos/pull/708 is released
              typos = pkgs-unstable.rustPlatform.buildRustPackage {
                pname = "typos";
                version = "1.16.9-stdin-inputs";

                src = prev.fetchFromGitHub {
                  owner = "dpc";
                  repo = "typos";
                  rev = "4ca840bdd466e2d7cdc15e2738afdb0572dfd297";
                  hash = "sha256-CASK1pZzbcgVssq0KDRYO7t6RjNe/i/5up2yjjyrvE8=";
                };

                cargoHash = "sha256-1D8C4/co8FFtcWxR/0TdgCFHi85PKButeE0TG/Qzql4=";
              };
            })
          ];
        };
        lib = pkgs.lib;
        flakeboxLib = mkLib pkgs {
          config = { };
        };

        src = flakeboxLib.filterSubPaths {
          root = builtins.path {
            name = "flakebox";
            path = ./.;
          };
          paths = [
            "Cargo.toml"
            "Cargo.lock"
            ".cargo"
            "flakebox-bin"
          ];
        };

        outputs =
          (flakeboxLib.craneMultiBuild { }) (craneLib':
            let
              craneLib = (craneLib'.overrideArgs {
                pname = "flexbox";
                nativeBuildInputs = [
                  pkgs.mold
                ];
                inherit src;
              });
            in
            rec {
              workspaceDeps = craneLib.buildWorkspaceDepsOnly { };
              workspaceBuild = craneLib.buildWorkspace {
                cargoArtifacts = workspaceDeps;
              };
              flakebox = craneLib.buildPackage { };
              flakeboxGroup = craneLib.buildPackageGroup { packages = [ "flakebox" ]; mainProgram = "flakebox"; };
            });


        checks =
          pkgs.callPackages ./checks {
            inherit pkgs;
            mkLib = mkLib;
          };
      in
      {

        inherit checks;
        lib = mkLib pkgs;

        packages = {
          bootstrap = pkgs.writeShellScriptBin "flakebox-bootstrap" "exec ${pkgs.bash}/bin/bash ${./bin/bootstrap.sh} ${./bin/bootstrap.flake.nix} \"$@\"";
          root = flakeboxLib.root;
          default = outputs.flakebox;
          docs = flakeboxLib.docs;
          fullChecks =
            (pkgs.callPackages ./checks {
              inherit pkgs;
              mkLib = mkLib;
              full = true;
            }).workspaceCross;
        };

        legacyPackages = outputs;

        devShells = flakeboxLib.mkShells {
          packages = [ pkgs.mdbook ];
        };

      });
}
