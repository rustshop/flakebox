# Rustshop Flakebox - Rust dev experience (DX) we can share and love.

* Integrate best Rust dev tooling and practices into your project in seconds.
* Learn, customize, improve and share as a part of the DX-focused community.
* Keep up to date with the evolving ecosystem with ease.

Rustshop is a vision of how working with Rust could and should be like.
Flakebox is all you need to bring that vision into your Rust project.

Just because you're a lone Open Source developer working on a spare
time project doesn't mean you don't deserve a DX of a mature team
with dedicated tooling team. Just because you're a part of dedicated
tooling system in a mature team, doesn't mean you shouldn't benefit
from all the best ideas wider community has to offer.

You don't have to copy, paste and keep updating the same set of of
scripts between tens of your projects.

There's a better way: Flakebox.

**Warning:** Rustshop Flakebox is currently very immature. Expect
rought edges and some amount of churn before we figure out the
core pieces. We're currently targeting developers already using
Nix Flakes and Nix Development shells that are interested in
more active partipation.

## Setting up Flakebox in your Rust project

#### Install Nix with Flake support

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
          # $. Use `mkDevShell` wrapper instead of the usual `mkShell`
          default = flakeboxLib.mkDevShell {
            packages = [ ];
          };

          # ... 

        };

      # ...

      }
```



