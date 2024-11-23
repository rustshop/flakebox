{
  description = "Toolkit for building Nix Flake development environments for Rust projects";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    systems.url = "github:nix-systems/default";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";

    crane = {
      url = "github:ipetkov/crane/?rev=b65673fce97d277934488a451724be94cc62499a"; # https://github.com/ipetkov/crane/releases/tag/v0.17.3
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs?rev=522d86121cbd413aff922c54f38106ecf8740107"; # stable channel https://github.com/tadfisher/android-nixpkgs/tree/stable
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
        lib = mkLib pkgs;

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
