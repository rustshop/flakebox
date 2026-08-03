# `flakeboxLib` functions

## `flakeboxLib.source`

Use `flakeboxLib.source` to declare exactly which project files a build can
read. Excluding unrelated files prevents their changes from invalidating Rust
build derivations.

The normal literal-path API validates every path and imports the selected
files once:

```nix
let
  buildPaths = [
    "Cargo.toml"
    "Cargo.lock"
    ".cargo"
    "flakebox-bin"
  ];

  src = flakeboxLib.source.fromPaths {
    root = ./.;
    paths = buildPaths;
    filter = flakeboxLib.source.filters.excludeDirectoriesNamed [ "specs" ];
  };
in
# ...
```

`root` must be a Nix path value, not a store-path string produced by
`builtins.path`. The subpaths must be relative, non-empty, stay below `root`, and
exist. The selected file sets preserve symlinks but omit empty directories.

Reuse path lists when later build stages need extra inputs:

```nix
buildSrc = flakeboxLib.source.fromPaths {
  root = ./.;
  paths = buildPaths;
  filter = flakeboxLib.source.filters.excludeDirectoriesNamed [ "specs" ];
};

testSrc = flakeboxLib.source.fromPaths {
  root = ./.;
  paths = buildPaths ++ [ "scripts" ];
  filter = flakeboxLib.source.filters.excludeDirectoriesNamed [ "specs" ];
};
```

Changes under `scripts` then invalidate tests without invalidating the Rust
build. Include every build dependency, including build-script inputs,
`include_*` macro inputs, generated-code inputs, assets, schemas, and fixtures.

### Fileset composition

`source.filesetFromPaths` returns a Nixpkgs file set for composition with
`pkgs.lib.fileset.union`, `unions`, `intersection`, and `difference`.
`source.fromFileset` performs the final source import:

```nix
let
  fs = pkgs.lib.fileset;
  source = flakeboxLib.source;
  buildFiles = source.filesetFromPaths {
    root = ./.;
    paths = buildPaths;
  };
in {
  buildSrc = source.fromFileset {
    root = ./.;
    fileset = buildFiles;
    filter = source.filters.excludeDirectoriesNamed [ "specs" ];
  };
  testSrc = source.fromFileset {
    root = ./.;
    fileset = fs.union buildFiles ./scripts;
    filter = source.filters.excludeDirectoriesNamed [ "specs" ];
  };
}
```

Use `fs.maybeMissing` when a selected path is intentionally optional.
`fromFileset` rejects files outside `root`.

### Directory-aware filters

`fromPaths` and `fromFileset` accept a canonical Nix source predicate of
`absolutePathString: type: bool`. Returning false for a directory prunes its
whole subtree. Flakebox provides `source.filters.all`, `any`, `not`, and
`excludeDirectoriesNamed` for composition:

```nix
buildSrc = flakeboxLib.source.fromPaths {
  root = ./.;
  paths = buildPaths;
  filter = flakeboxLib.source.filters.excludeDirectoriesNamed [ "specs" ];
};
```

A regular file named `specs` is retained; directories with that basename are
pruned at any selected depth.

### Glob filtering

`source.fromGlobs` is an explicit native-traversal alternative for large trees.
It supports Nixpkgs `sourceByGlobs` inclusion patterns such as `src/**`, `*.py`,
and `**/*.py`, and accepts the same optional `filter`. It retains matched empty
directories and requires Nixpkgs 26.05 or newer. Prefer literal paths and
fileset composition unless measurements justify glob traversal.

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

`flakeboxLib.cargoCrap` exposes Flakebox's packaged `cargo-crap` derivation for
custom Nix checks and reports.

Most projects should prefer the default `cargo-crap` module integration, which
adds the tool to dev shells, generates `.cargo-crap.toml`, and provides the
`just crap` helper. Use `flakeboxLib.cargoCrap` directly when composing custom
crane derivations, CI report jobs, or baseline/regression gates.
