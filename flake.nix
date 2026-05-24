{
  description = "Toolkit for building Nix Flake development environments for Rust projects";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    systems.url = "github:nix-systems/default";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";

    crane = {
      url = "github:ipetkov/crane/v0.23.3";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs?rev=d3cbdd2a82b3d054b4e283d28ba27548186a88e7"; # stable channel https://github.com/tadfisher/android-nixpkgs/tree/stable
      inputs.flake-utils.follows = "flake-utils";
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
    }@inputs:
    let
      overlays.default = final: prev: {
        wild-unwrapped =
          let
            version = "0.9.0";
            src = prev.fetchFromGitHub {
              owner = "wild-linker";
              repo = "wild";
              rev = version;
              hash = "sha256-v4lPgZDPvRTAekkU9Vku9llgpOsaVtKt91VFUGrEeKw=";
            };
            cargo = fenix.packages.${final.system}.latest.cargo;
            rustc = fenix.packages.${final.system}.latest.rustc;
            rustPlatform = final.makeRustPlatform {
              inherit cargo rustc;
            };
          in
          prev.wild-unwrapped.overrideAttrs (old: {
            inherit version src;
            cargoDeps = rustPlatform.fetchCargoVendor {
              inherit src;
              name = "wild-unwrapped-${version}-vendor";
              hash = "sha256-ADJLtTRXcVWcbvgwXvCs0wxcGp2XP1LZJUJ4hpuzVHQ=";
            };
            buildInputs = (old.buildInputs or [ ]) ++ [ final.zstd ];
            postFixup = (old.postFixup or "") + ''
              patchelf --add-rpath ${final.lib.makeLibraryPath [ final.zstd ]} $out/bin/wild
            '';
            nativeBuildInputs = [
              cargo
              rustc
              rustPlatform.cargoSetupHook
              rustPlatform.cargoBuildHook
              rustPlatform.cargoInstallHook
            ]
            ++ final.lib.filter (
              input:
              let
                inputString = toString input;
              in
              !(final.lib.hasInfix "cargo-setup-hook" inputString)
              && !(final.lib.hasInfix "cargo-build-hook" inputString)
              && !(final.lib.hasInfix "cargo-install-hook" inputString)
            ) (old.nativeBuildInputs or [ ]);
          });

        wild = prev.wild.override {
          bintools = final.wild-unwrapped;
        };
      };

      mkLib =
        pkgs:
        import ./lib {
          inherit
            pkgs
            crane
            fenix
            android-nixpkgs
            nixpkgs
            ;
        };
    in
    {
      inherit overlays;

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
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlays.default ];
        };

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

        checks =
          pkgs.callPackages ./checks {
            inherit pkgs;
            mkLib = mkLib;
          }
          // {
            flakebox = flakeboxLib.flakeboxBin;
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
