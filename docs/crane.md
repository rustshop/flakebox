# Crane and `craneLib`

Flakebox builds on top of [Crane](https://crane.dev/) - A Nix library for building cargo projects.
It allows composing arbitrarily complex chains of `cargo`-based build steps as Nix derivations,
using a convenient API. Under the hood it's based on passing compressed `./target` artifacts as an
incremental list of layers, offering compact storage, high performance, and efficient caching.

We recommend Flakebox users to familiarize with Crane.


## Flakebox `craneLib` extensions

Flakebox extends the `craneLib` it produced with important additional functionality, built on
the experiences of patterns useful in non-trivial Rust projects.


### `craneLib.overrideArgs`

Flakebox formalizes as common pattern of merging `commonArgs` into arguments passed to `craneLib`
calls:

```nix
let
  my-crate-1 = craneLib.buildPackage (commonArgs // {
    inherit cargoArtifacts;
    # ...
  });

  my-crate-2 = craneLib.buildPackage (commonArgs // {
    inherit cargoArtifacts;
    # ...
  });
in
 ...
```

Flakebox `craneLib` can store arguments internally and merge them automatically
with all the direct arguments:

```
let
  craneLib = craneLib'.overrideArgs {
    # common args ...
  };

  my-crate-1 = craneLib.buildPackage {
    inherit cargoArtifacts;
    # ...
  };

  my-crate-2 = craneLib.buildPackage {
    inherit cargoArtifacts;
    # ...
  };
in
  ...
```

We find this functionality leading to much easier to read code. In addition,
thanks to Flakebox internal arguments merging, avoiding a common pitfall
of shallow merge operator (`//`) not merging lists like `buildInputs`,
`nativeBuildInputs` and `packages`.

### `craneLib.overrideArgsDepsOnly`

`overrideArgsDepsOnly` works like `overrideArgs`, but unlike it, the arguments passed to it
are forwarded only to `*DepsOnly` calls (explicit and implicit).

### `craneLib.overrideProfile`

`overrideProfile` works like `overrideArgs` but changes only the build profile
(stored and handles as `CARGO_BUILD_PROFILE` argument / env variable by Crane).
