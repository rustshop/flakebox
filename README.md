<!-- WARNING: THIS FILE IS AUTO-GENERATED. EDIT ./docs/README.md instead -->

<p align="center">
  <a href="https://github.com/rustshop/flakebox/actions/workflows/flakebox-ci.yml">
      <img src="https://github.com/rustshop/flakebox/actions/workflows/flakebox-ci.yml/badge.svg" alt="Github Actions CI Build Status">
  </a>
  <a href="https://matrix.to/#/#flakebox:matrix.org"><img alt="Chat on Matrix" src="https://img.shields.io/matrix/flakebox:matrix.org.svg"></a>
  <a href="https://github.com/rustshop/flakebox/discussions">
    <img src="https://img.shields.io/badge/commmunity-discussion-blue" alt="Flakebox Github Discussions">
  </a>
</p>

# Rustshop Flakebox

## Rust dev experience we can share and love.

Flakebox is to your Rust project, what NixOS is to your OS, and
home-manager to your home directory.

Flakebox is based on experiences building and maintaining sophisticated
and demanding Rust projects using Nix. It integrates wide range of
ideas, tools and techniques into a powerful yet easy to use toolkit.

Notable features include:

* library for building complex and highly optimized Nix-based build pipelines;
* efficient multi-stage incremental build caching;
* cross-compilation support, including non-Rust dependencies;
* dev shells with integrated best practices, tooling and cross-compilation;
* CI workflow generation;
* seamless updates.

With Flakebox you can start using Nix in your Rust project in minutes
and share the experience and tools between all your projects.

Built-in Nix Modules based configuration system allows the same level of
customization and extensibility as NixOS itself.

The documentation and tools will teach you how to start and then evolve
your project to employ the power of Nix to handle complex build pipelines,
CI requirements and testing setups.

The project is open for ideas and collaboration. Learn, customize, improve and share
as a member of the DX-focused community and use seamless updates
to stay up to date with the evolving ecosystem.

Rustshop is a vision of how working with Rust could and should be like.
Flakebox will bring that vision into your projects.

**Warning:** Rustshop Flakebox is currently very immature. Expect
rough edges and some amount of churn before we figure out the
core pieces.

## Join the Community

[Our Github Discussions](https://github.com/rustshop/flakebox/discussions)
is the best place to ask questions and participate in building Flakebox. Don't be shy.

If you're looking for more interactive conversation, join [Flakebox Matrix channel](https://matrix.to/#/#flakebox:matrix.org).

# Flakebox Book ToC

The best way to view the Flakebox documentation is by running:

```
nix build github:rustshop/flakebox#docs && xdg-open result/index.html
```

In projects already using Flakebox, the documentation can be accessed using `flakebox docs` command.

# ToC

[Introduction](./docs/README.md)

- [Technical Introduction](./docs/technical-details.md) 

# Getting Started

- [Tutorial: Flakebox in a New Project](./docs/building-new-project.md)


# Reference Manual

- [Crane and `craneLib`](./docs/crane.md)
- [`flakeboxLib` functions](./docs/flakeboxLib.md)
- [Native toolchains](./docs/native-toolchains.md)
- [Android toolchains](./docs/android-toolchains.md)
- [iOS toolchains](./docs/ios-toolchains.md)
- [Config Options](./docs/nixos-options.md)

# Stale, might need a rework

- [Setting up Flakebox](./docs/getting-started.md)

<!-- WARNING: THIS FILE IS AUTO-GENERATED. EDIT ./docs/README.md instead -->
