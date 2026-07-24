# ARCH-flakebox: Flakebox architecture

Flakebox is a Nix-flake-delivered toolkit for Rust development environments.
Its main boundaries are the Nix library in `lib/`, the `flakebox` CLI, the
default project template, user documentation, and checks built against the
public library.

`flake.nix` exposes the overlay, template, and `mkLib` constructor, then
instantiates system-specific packages, checks, and development shells. `mkLib`
evaluates Flakebox's built-in modules together with caller modules and
configuration. The resulting library instance provides generated project
state, shells, source selection, target and toolchain construction, Crane
integration, build-matrix assembly, and supporting helpers. The detailed
library topology is described by
[ARCH-flakebox-nix-library](../lib/specs/ARCH-flakebox-nix-library.md).

Modules contribute declarative project state and shell behavior. The library
materializes that state as an immutable candidate root and exposes it to
development shells. The CLI is the imperative boundary: it checks the candidate
against a mutable project checkout and explicitly installs it when requested;
it also owns local lint and documentation entry points. It does not generate
the candidate contents.

Rust build inputs flow through explicit source selection into enhanced Crane
instances and then through the configured profile and toolchain cells.
Directories named `specs` contain governing documentation, not build inputs,
and repository-derived build sources prune them recursively. Checks exercise
the public library with evaluation assertions, realistic fixture builds, and
generated integration behavior. User procedures and API details remain in
`docs/`, while generated option documentation owns the complete configuration
reference.
