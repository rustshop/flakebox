# Setting up Flakebox with a Flake template

If you are starting a new project, you can
use Nix template with very simple setup process:

```
mkdir my-project
cd my-project
nix flake init -t github:rustshop/flakebox
git init .
git add .
git commit -m "Start from a Flakebox template"
```

Replace template name:

```
> grep -r flakebox-project .
./flake.nix:        projectName = "flakebox-project";
./Cargo.toml:name = "flakebox-project"
```

Start the shell and follow the instructions

```
> nix develop
warning: Git tree '/home/dpc/tmp/my-project' is dirty
⚠️  Flakebox files not installed. Call `flakebox install`.
> flakebox install
> cargo build
> git add Cargo.lock
> git commit -m "Install flakebox files"
```

See `nix build` works:

```
nix build .#
```
