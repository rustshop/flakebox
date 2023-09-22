# Setting up Flakebox in your Rust project

## Install Nix with Flake support

Flakebox leverages the power of Nix Flakes. Don't worry, you don't
have to know Nix to use it. But you do need to install Nix with Flake
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

#### Set up via bootstrap via script

If you're not familiar with Nix, and you want an easy way get started,
you can use a script that will set it up. Otherwise skip to the next
section.

After you install Nix, you can bootstrap Flakebox in any Rust project
by running the following in its root directory:

```sh
nix run github:rustshop/flakebox#bootstrap
```

Then read the output and follow the instructions. There won't be many.

#### Setup manually

If you're an existing Nix Flake user and already have a `flake.nix` file
in your project, you can integrate Flakebox manually:

```nix
  # 1. Add new input to the input section
  inputs = {

    # ...

    flakebox = {
      url = "github:rustshop/flakebox";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ...
  }

  # 2. Add the new input to the arguments of the output section
  outputs = { self, nixpkgs, flakebox, ... }:

      # ...

      let
        # 3. Set up the flakebox lib for your system
        flakeboxLib = flakebox.lib.${system};
      in
      {

      # ...

        devShells = {
          # 4. Use `mkDevShell` wrapper instead of the usual `mkShell`
          default = flakeboxLib.mkDevShell {
            packages = [ ];
          };

          # ... 

        };

      # ...

      }
```
