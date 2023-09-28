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
          x = (craneLib.overrideScope' (self: prev: { })).buildDepsOnly
            {
              nativeBuildInputs = [ pkgs.mold ];
              src = builtins.path {
                name = "flakebox";
                path = ./.;
              };
            };
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

            packagesFn = craneLib: rec {
              workspaceDeps = craneLib.buildWorkspaceDepsOnly { };
              workspaceBuild = craneLib.buildWorkspace {
                cargoArtifacts = workspaceDeps;
              };
              flakebox = craneLib.buildPackage {
                pname = "flakebox";
                doCheck = false;
              };
            };
            profilesFn = craneLib: (craneLib.overrideScope' (self: prev: {
              args = prev.args // {
                pname = "flexbox";
                nativeBuildInputs = [ pkgs.mold ];
                inherit src;
              };
            })).mapWithProfiles
              packagesFn [ "dev" "ci" "release" ];
          in
          (
            (profilesFn craneLib)
            // (flakeboxLib.mapWithToolchains
              (toolchainName: craneLib: profilesFn craneLib)
              {
                aarch64-linux = flakeboxLib.mkFenixToolchain {
                  crossTargets = [ "aarch64-unknown-linux-gnu" ];
                  args = {
                    CARGO_BUILD_TARGET = "aarch64-unknown-linux-gnu";
                    CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER =
                      let
                        inherit (pkgs.pkgsCross.aarch64-multiplatform.stdenv) cc;
                      in
                      "${cc}/bin/${cc.targetPrefix}cc";
                  };
                };
              })
          );

        devShells = {
          default = flakeboxLib.mkDevShell {
            packages = [ pkgs.mold pkgs.mdbook ];
          };
        };
      });
}
