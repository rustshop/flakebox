# Flakebox (Rust + Nix) best practices

## Use `nix develop` and not `nix build` for local development

No matter how optimized, as a general purpose tool Nix will never
be able to match the the speed and convenience of incremental
builds with `cargo` itself.

Repeadly calling `nix build .#package` during local development
can quickly become unbearable for developers working on
something.

Because of that during daily work developers should rely on
`nix develop` (nix dev shells) to provide them with a reproducible
building environment, where they can compile and run all the
tests, scripts and utilities as they see fit, without being
forced to recompile code as Nix packages.

In essence it is the same problem that people trying to use
Docker for daily work would hit, often resolved by mounting
the source code as a volume into a Docker container providing
reproducible environment, without rebuilding project from
scartch every time. Such a setup can be thought of as "poor man's
Nix dev shell".

Scripts and utilities should be written in such a way to work
all the same inside dev shell and when running inside Nix
derivation build, which should be easy and natural.

Use `nix build` in CI or for things that don't require
common/incremental rebuilds.

## Use custom `ci` cargo build profile

It's a good idea to create a custom cargo build profile(s)
and use them in the Nix-based CI to improve the CI times.

Example:

```toml
[profile.ci]
inherits = "dev"
debug = 1
incremental = false
```

This can be combined with building the most performance-relevant
dependencies with optimizations, either manually:

```toml
[profile.ci.package]
secp256k1 = { opt-level = 2 }
```

or for all dependencies:

```
[profile.ci.package."*"]
opt-level = 2
```

See [build profile Overrides section in The Cargo Book](https://doc.rust-lang.org/nightly/cargo/reference/profiles.html#overrides).


### Filter source code to avoid unnecessary rebuilds


Avoiding rebuilds is an important part of optimized Nix-based CI. It's especially
important in slow to compile language like Rust.

Flakebox provides `flakeboxLib.filterSubPaths` function for convenient
source code filtering.


### Use mold when possible

[`mold`](https://github.com/rui314/mold) is an extremely fast linker.
Especially during daily dev work, each incremental Rust codebase build
tends to spend a significant time in linking phase. `mold` helps a lot.

Flakebox will automatically link using `mold` on Linux, also taking care of
some important low level NixOS details.

### TBD: `cargo` accidental-recompilation prevention

## Gate high CRAP scores with cargo-crap

Flakebox provides `cargo-crap` in development shells by default, generates a
shared `.cargo-crap.toml`, and adds a `just crap` helper that runs
`cargo-crap --workspace`.

The pre-commit cargo-crap gate is intentionally opt-in because CRAP checks can be
more expensive and project-specific than lightweight formatting or spelling
checks. Enable it when a project has chosen suitable thresholds or coverage
inputs:

```nix
{
  cargo-crap.pre-commit = {
    enable = true;
    args = [
      "--workspace"
      "--threshold"
      "100"
      "--fail-above"
    ];
  };
}
```

Customize the generated `.cargo-crap.toml` by setting
`cargo-crap.config.content`. Disable only that generated file with
`cargo-crap.config.enable = false`, or disable the whole cargo-crap integration
with `cargo-crap.enable = false`.


## Enforce structural rules with ast-grep

Flakebox installs [ast-grep](https://ast-grep.github.io/) and runs
`ast-grep scan` from the generated pre-commit hook when the repository contains
a non-empty `sgconfig.yml`. It also generates an `ast-grep` just recipe.

Use ast-grep's standard project layout:

```yaml
# sgconfig.yml
ruleDirs:
  - .config/ast-grep/rules
testConfigs:
  - testDir: .config/ast-grep/rule-tests
```

Keeping `sgconfig.yml` at the repository root preserves ast-grep's automatic
project discovery. Store the rules and their tests under
`.config/ast-grep/` to avoid adding tool-specific directories at the root.
Then run `just ast-grep` to scan the project or `ast-grep test` to test the
rules.

Projects can promote selected rules to commit-blocking errors:

```nix
ast-grep = {
  pre-commit.args = [
    "--error=complex-conditional"
    "--error=deeply-nested-if"
  ];
};
```
