{
  description = "Toolkit for building Nix Flake development environments for Rust projects";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    # nixpkgs.url = "github:nixos/nixpkgs/?rev=8f40f2f90b9c9032d1b824442cfbbe0dbabd0dbd";
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
  outputs = { self, nixpkgs, flake-utils, crane, fenix, android-nixpkgs }:

    let
      mkLib = pkgs: import ./lib
        {
          inherit pkgs crane fenix android-nixpkgs;
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
        flakeboxLib = mkLib pkgs {
          config = {
            github.ci.buildOutputs = [
              ".#ci.flakebox"
              ".#aarch64-android.ci.flakebox"
              ".#x86_64-android.ci.flakebox"
              ".#arm-android.ci.flakebox"
              ".#docs"

              # too slow
              # ".#aarch64-linux.ci.flakebox"
              # ".#x86_64-linux.ci.flakebox"
            ];
          };
        };

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
      in
      {
        lib = mkLib pkgs;

        packages = {
          bootstrap = pkgs.writeShellScriptBin "flakebox-bootstrap" "exec ${pkgs.bash}/bin/bash ${./bin/bootstrap.sh} ${./bin/bootstrap.flake.nix} \"$@\"";
          root = flakeboxLib.root;
          default = outputs.flakebox;
          docs = flakeboxLib.docs;
        };

        checks = {
          workspaceBuild = outputs.ci.workspaceBuild;
          aarch64-linux-workspaceBuild = outputs.aarch64-linux.ci.workspaceBuild;
        };

        legacyPackages = outputs;

        devShells = {
          default = flakeboxLib.mkDevShell {
            packages = [ pkgs.mold pkgs.mdbook ];
          };

          cross = flakeboxLib.mkDevShell {
            packages = [ pkgs.mold pkgs.mdbook ];
            # toolchain = flakeboxLib.mkFenixMultiToolchain { toolchains = { default = flakeboxLib.mkFenixToolchain { }; }; };
            toolchain = flakeboxLib.mkFenixMultiToolchain { };
          };

          crossFast = flakeboxLib.mkDevShell {
            packages = [ pkgs.mold pkgs.mdbook ];
            toolchain = flakeboxLib.mkFenixMultiToolchain {
              toolchains = pkgs.lib.getAttrs [
                "aarch64-android"
                "i686-android"
                "x86_64-android"
                "arm-android"
              ]
                (flakeboxLib.mkStdFenixToolchains { });
            };
          };
        };
      });
}
