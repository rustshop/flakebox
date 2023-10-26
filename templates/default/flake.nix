{
  description = "Flakebox Project template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flakebox.url = "github:rustshop/flakebox";
  };

  outputs = { self, nixpkgs, flake-utils, flakebox }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        projectName = "flakebox-project";

        flakeboxLib = flakebox.lib.${system} {
          config = {
            github.ci.buildOutputs = [ ".#ci.${projectName}" ];
          };
        };

        buildPaths = [
          "Cargo.toml"
          "Cargo.lock"
          "src"
        ];

        buildSrc = flakeboxLib.filterSubPaths {
          root = builtins.path {
            name = projectName;
            path = ./.;
          };
          paths = buildPaths;
        };

        multiBuild =
          (flakeboxLib.craneMultiBuild { }) (craneLib':
            let
              craneLib = (craneLib'.overrideArgs {
                pname = projectName;
                src = buildSrc;
                nativeBuildInputs = [ ];
              });
            in
            {
              ${projectName} = craneLib.buildPackage { };
            });
      in
      {
        packages.default = multiBuild.${projectName};

        legacyPackages = multiBuild;

        devShells = flakeboxLib.mkShells { };
      }
    );
}
