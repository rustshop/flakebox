# Flakebox - Technical Introduction

Note: Due to immaturity this project is part-vision/TODO and part-documentation
at this point.

Flakebox is published a Nix Flake in https://github.com/rustshop/flakebox
repository. This way it can be easily included in any other Flake
of any Rust project.

By the virtue of being a Nix Flake, project using Flakebox can easily
lock its version, update it, override its own inputs, etc. in addition
to the reproducibility that Nix provides.

### The goal

Functionality of Flakebox is meant to offer a complete and consistent
handling of all the common aspects of Rust project development:

* building Rust projects with Rust,
* setting up configuration files (e.g. git hooks, commit templates, `justfile`),
* integrating all the best lints (e.g. [`typos`](https://github.com/crate-ci/typos), [`semgrep`](https://semgrep.dev/), formatters, etc.),
* integrating all the best utilities,
* setting up Github Actions workflow files,
* providing standardized tools and scripts for handling Rust project.

with a possibility to customize and disable each part.

To make it clear: Flakebox doesn't just setup/install some tools. It fully integrates
them into cohesive and convenient environment, so e.g. all relevant lints from
all the enabled linters run both in git's `pre-commit` hook, and in the CI, etc.
The goal is to get by default a level of end to end polish that only the largest
and most mature projects usually have, all in just few lines of Nix code.

## Flakebox `lib` output

Flakebox's Flake exposes a `lib` flake output which allows:

* creating Flakebox Nix development shells,
* customizing all settings,
* extending with own modules,
* building project artifacts form Rust code using Nix derivations.

## Flakebox Nix development shells

Flakebox Nix development shells are standard `nix develop` shells,
but with all the integration and configuration taken care of.

To facilitate generation of tool/service/application specific
files, and for other DX purposes a `flakebox` CLI tool is prided
in development shells.

`Flakebox` will detect when its flake input, or desired configuration
changed and prompt the user to run `flakebox install` to update
all the generated files, which can then be committed into the project.
This is done so that all the tools (like Github Actions) expecting files
in certain places, and all the users viewing the project without
using development shells find everything where they expect.


### Updating Flakebox

To update flakebox version used by the project, one would start by updating
its flake input, e.g. with `nix flake update`.

Then the Nix development shell will prompt the user to run `flakebox install`,
which will then overwrite old files with their new versions. All changes
can be then committed and pushed a PR to the project.
