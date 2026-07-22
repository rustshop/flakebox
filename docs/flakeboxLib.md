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

### Cell-aware common build arguments

`craneMultiBuild` accepts an optional `argsFor` resolver for build arguments
that depend on the selected toolchain/target cell:

```nix
(flakeboxLib.craneMultiBuild {
  argsFor =
    {
      toolchainName,
      packages,
      capabilities,
    }:
    pkgs.lib.optionalAttrs capabilities.targetBuildInputs {
      buildInputs = [ packages.buildInputs.openssl ];
      nativeBuildInputs = [ packages.nativeBuildInputs.pkg-config ];
    };
}) (craneLib: {
  app = craneLib.buildPackage {
    inherit src;
  };
})
```

Flakebox evaluates `argsFor` once for each selected cell, before it maps that
cell over Cargo profiles. The resolver receives:

* `toolchainName`: the cell's key in `toolchains`.
* `packages.buildInputs`: the package scope for target libraries.
* `packages.nativeBuildInputs`: the package scope for build-host tools that
  configure or emit artifacts for the target.
* `packages.depsBuildBuild`: the package scope for build-host tools that emit
  build-host artifacts.
* `capabilities.targetBuildInputs`: whether the cell has a truthful Nixpkgs
  target package universe.

For ordinary Nixpkgs cross cells these roles map to `pkgsHostTarget`,
`pkgsBuildHost`, and `pkgsBuildBuild`, respectively. Native cells expose the
equivalent roles from the native package set.

Android, `wasm32-unknown-unknown`, and other SDK or Rust-only cells do not
pretend that native or WASI packages are target packages. Check
`capabilities.targetBuildInputs` before selecting target dependencies.
Accessing an unavailable role fails with the toolchain/cell name and the
missing role. Custom toolchains may omit `dependencyContext` as long as their
`argsFor` result does not access `packages`; role access then fails lazily.
Custom toolchains that support role-scoped packages can provide:

```nix
dependencyContext = {
  packages = {
    depsBuildBuild = crossPkgs.pkgsBuildBuild;
    nativeBuildInputs = crossPkgs.pkgsBuildHost;
    buildInputs = crossPkgs.pkgsHostTarget;
  };
};
```

The merge order is: the cell's built-in target/common arguments, then the
attrset returned by `argsFor`, then arguments passed to an individual Crane
build call. All layers use the existing `overrideArgs`/`mergeArgs` behavior:
`buildInputs`, `nativeBuildInputs`, and `packages` concatenate from left to
right; `env` attrsets merge with later values winning; and every other
attribute, including `depsBuildBuild`, uses the later value. Omitting `argsFor`
preserves the existing build path.

This API selects explicit artifacts for Flakebox's existing manual Cargo-cross
model. It does not turn the root Rust derivation into a fully spliced Nixpkgs
cross derivation.

## `flakeboxLib.cargoCrap`

`flakeboxLib.cargoCrap` exposes flakebox's packaged `cargo-crap` derivation for
custom Nix checks and reports.

Most projects should prefer the default `cargo-crap` module integration, which
adds the tool to dev shells, generates `.cargo-crap.toml`, and provides the
`just crap` helper. Use `flakeboxLib.cargoCrap` directly when composing custom
crane derivations, CI report jobs, or baseline/regression gates.
