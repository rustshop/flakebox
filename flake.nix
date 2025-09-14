{
  description = "Toolkit for building Nix Flake development environments for Rust projects";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    systems.url = "github:nix-systems/default";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";

    crane = {
      url = "github:ipetkov/crane/?rev=efd36682371678e2b6da3f108fdb5c613b3ec598";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs?rev=7dc07be20c7a516cc7490969c4072ff692fb1b27"; # stable channel https://github.com/tadfisher/android-nixpkgs/tree/stable
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      flake-utils,
      nixpkgs,
      crane,
      fenix,
      android-nixpkgs,
      ...
    }:
    let
      mkLib =
        pkgs:
        import ./lib {
          inherit
            pkgs
            crane
            fenix
            android-nixpkgs
            ;
        };
    in
    {
      templates = {
        default = {
          path = ./templates/default;
          description = "Flakebox default project template";
        };
      };

      lib = {
        inherit mkLib;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        flakeboxLib = mkLib pkgs {
          config = {
            github.ci.cachixRepo = "rustshop";
            just.importPaths = [
              "justfile.custom"
            ];
            motd = {
              enable = true;
              command = ''
                >&2 echo "Welcome to Flakebox dev env"
              '';
            };
          };
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

        outputs = (flakeboxLib.craneMultiBuild { }) (
          craneLib':
          let
            craneLib = (
              craneLib'.overrideArgs {
                pname = "flexbox";
                nativeBuildInputs = [
                  pkgs.mold
                ];
                inherit src;
              }
            );
          in
          rec {
            workspaceDeps = craneLib.buildWorkspaceDepsOnly { };
            workspaceBuild = craneLib.buildWorkspace {
              cargoArtifacts = workspaceDeps;
            };
            flakebox = craneLib.buildPackage { };
            flakeboxGroup = craneLib.buildPackageGroup {
              packages = [ "flakebox" ];
              mainProgram = "flakebox";
            };
          }
        );

        checks = pkgs.callPackages ./checks {
          inherit pkgs;
          mkLib = mkLib;
        };
      in
      {
        inherit checks;

        packages = {
          bootstrap = pkgs.writeShellScriptBin "flakebox-bootstrap" "exec ${pkgs.bash}/bin/bash ${./bin/bootstrap.sh} ${./bin/bootstrap.flake.nix} \"$@\"";
          root = flakeboxLib.root;
          default = flakeboxLib.flakeboxBin;
          docs = flakeboxLib.docs;
        };

        legacyPackages = outputs // {
          fullChecks =
            (pkgs.callPackages ./checks {
              inherit pkgs;
              mkLib = mkLib;
              full = true;
            }).workspaceCross;
        };

        devShells = flakeboxLib.mkShells {
          packages = [ pkgs.mdbook ];
        };

      }
    );
}
