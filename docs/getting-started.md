# Setting up Flakebox in your Rust project

## Install Nix with Flake support

Flakebox leverages the power of Nix Flakes. Don't worry, you should
be able to use it even if you don't know Nix. But you do need to install Nix with Flake
support, and all other developers working on your project will need
Nix installed as well.

We promise - this is the only requirement that you need to
take care of, just so Flakebox can take care of all other things
for you.

If you're new to Nix, we recommend using [Determinate Nix Installer](https://zero-to-nix.com/start/install),
which should come down to running:

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

## Setup Flakebox

If you're starting in a project without `flake.nix`, see [Tutorial: Flakebox in a New Project](./building-new-project.md)
instead.

Following modifications to `flake.nix` are needed:

```nix
  inputs = {

    # ...

    # Add new input to the input section
    flakebox = {
      url = "github:rustshop/flakebox";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ...
  }

  # Add the new input to the arguments of the output section
  outputs = { self, nixpkgs, flakebox, ... }:

      # ...

      let
        # Set project name
        projectName = "my-project";

        pkgs = nixpkgs.legacyPackages.${system};

        # Set up the flakebox lib for your system
        flakeboxLib = flakebox.lib.mkLib pkgs {
          # customizations go here
          config = {
            typos.pre-commit.enable = false;
          };
        };

        # Add list of Rust-source paths
        buildPaths = [
          "Cargo.toml"
          "Cargo.lock"
          ".cargo"
          "src"
        ];

        # Filter Rust source code
        buildSrc = flakeboxLib.filterSubPaths {
          root = builtins.path {
            name = projectName;
            path = ./.;
          };
          paths = buildPaths;
        };

        # Add toolchain x profile build matrix
        multiBuild =
          (flakeboxLib.craneMultiBuild { }) (craneLib':
            let
              craneLib = (craneLib'.overrideArgs {
                pname = projectName;
                src = buildSrc;
              });
            in
            {
              package = craneLib.buildPackage { };
            });

      in
      {

        # Expose external output packages
        packages.default = multiBuild.package;

        # Expose internal (CI) packages
        legacyPackages = multiBuild;


        devShells = flakeboxLib.mkShells {};

          # ... 

      }
```

Start the dev shell:

```
nix develop
```

Inside it install all the Flakebox-generated files:

```
flakebox install
```
