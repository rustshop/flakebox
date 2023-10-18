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
home-manager to your home directory. And more.

Flakebox is based on experiences building and maintaining sophisticated
and demanding Rust projects using Nix. It integrates wide range of
ideas, tools and techniques into a powerful yet easy to use toolkit.

Flakebox is more about Rust than Nix, and is focused on onboarding
Rust developers that want to use Nix in their projects.

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

## Try it out

The easiest way to see how it works in practice is
checking some projects that use it, e.g. ones listed in
[*I'm using it!* community discussions](https://github.com/rustshop/flakebox/discussions/categories/i-m-using-it).

In particular, feel free to submit a fake PR to [htmx-sorta](https://github.com/rustshop/htmx-sorta). Clone it,
install Nix via [DeterminateSystems nix-installer](https://github.com/DeterminateSystems/nix-installer) if you
don't have Nix yet, enter the dev shell with `nix develop`, make
some changes and submit a PR. It's OK, we don't mind, it's a demo app.

## Join the Community

[Our Github Discussions](https://github.com/rustshop/flakebox/discussions)
is the best place to ask questions and participate in building Flakebox. Don't be shy.

If you're looking for more interactive conversation, join [Flakebox Matrix channel](https://matrix.to/#/#flakebox:matrix.org).

