# ARCH-flakebox-nix-library: Flakebox Nix library architecture

This record refines [ARCH-flakebox](../../specs/ARCH-flakebox.md) for `lib/`.

`mkLib pkgs { modules, config }` is the library composition boundary. It
evaluates built-in modules, caller extensions, and caller configuration, then
returns a scoped library instance bound to one package set and system. Modules
declare options and contribute through shared aggregation points for generated
repository files, shell environment and hooks, Git hooks, Just rules, and
GitHub workflows.

The generated root is the declarative desired project state. The library
materializes it, gives it a content identity, and exposes it and its generated
shell hook to development shells. The `flakebox` CLI, outside this scope, owns
comparison and synchronization with a mutable worktree.

Target constructors provide target-specific build arguments and Rust component
targets. Toolchain constructors combine those descriptions with Fenix and an
enhanced Crane instance. `craneMultiBuild` maps consumer-defined outputs across
the configured toolchain and Cargo-profile cells while resolving each cell's
build-input roles.

Source construction remains explicit and caller-owned. Callers select every
input their build or check consumes and apply additional predicates where
needed. Repository-derived sources exclude directories named `specs`
recursively so governing records do not enter builds or invalidate their
source identities. `docs/flakeboxLib.md` owns the public source and build-matrix
API details; checks provide executable conformance coverage.
