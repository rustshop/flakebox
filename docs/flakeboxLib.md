# `flakeboxLib` functions

## `flakeboxLib.filterSubPaths`

A recommended way to create a Nix path containing only selected list
of files and directories.

This is very important to avoid Nix unnecessarily recompiling Rust
code due to changes in irrelevant files.

Since Nix does not understand
`cargo` it has to assume that change to any input (e.g. file) used in a build
step (derivation) could have caused the result to change. The only reason
to avoid it is to not pass such files (filter them out).

Notably `craneLib` already performs certain filtering, in particular for
`*DepsOnly` functions, but for best results it's necessary to handle
it manually.

While Nix includes functions for that purposes, we've found the `filterSubPaths`
an easy to use and maintain.

```nix
let
  root = builtins.path {
    name = "flakebox";
    path = ./.;
  };
  src = flakeboxLib.filterSubPaths {
    inherit root;
    paths = [
      "Cargo.toml"
      "Cargo.lock"
      ".cargo"
      "flakebox-bin"
    ];
  };
in
  ...
```

It's a good practice to concatenate list of paths when chaining
post-build derivations.

```nix
let
  root = builtins.path {
    name = "flakebox";
    path = ./.;
  };
  buildPaths = [
      "Cargo.toml"
      "Cargo.lock"
      ".cargo"
      "flakebox-bin"
    ];
  src = flakeboxLib.filterSubPaths {
    inherit root;
    paths = buildPaths;
  };
in {
  #...
  testXyz = craneLib.buildCommand {
    cargoArtifacts = workspaceBuild;
    src = flakeboxLib.filterSubPaths {
      inherit root;
      paths = buildPaths ++ [ "scripts" ];
    };

    cmd = ''
      patchShebangs ./scripts
      ./scripts/test-xyz.sh
    '';
  };
}
```

Since `"scripts"` path is included only in the `src`
for tests, changes to test files will not cause
Rust code to rebuild.

## `flakeboxLib.craneMultiBuild `

A recommended to build the project with Nix, as it handles both build profiles and cross-compilation without additional effort.

The result of call to `craneMultiBuild` is conceptually a matrix of all supported cargo build profiles and
supported toolchains. A nested set with following keys:

* `<output>` - i.e. `workspaceDeps`, `workspaceBuild`, `flakebox-tutorial` are builds using default (`release`) building profile and `default` (native) toolchain
* `<profile>.<output>` - e.g. `dev.workspaceDeps`, `release.workspaceBuild`, `ci.flakebox-tutorial` are builds using `<ci>` building profile and `default` (native) toolchain
* `<toolchain>.<profile>.<output>` - e.g. `nightly.dev.workspaceDeps`, `aarch64-android.release.flakebox-tutorial` are builds using `<ci>` build profile and `<toolchain>`

See [Tutorial: Flakebox in a New Project](./building-new-project.md) for more information.
