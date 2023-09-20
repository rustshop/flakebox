{ pkgs, crane, fenix }:
pkgs.lib.makeScope pkgs.newScope (self:
let
  inherit (self) callPackage;
  system = pkgs.system;

  fenixChannel = fenix.packages.${system}.stable;
  fenixChannelNightly = fenix.packages.${system}.latest;

  fenixToolchain = (fenixChannel.withComponents [
    "rustc"
    "cargo"
    "clippy"
    "rust-analysis"
    "rust-src"
  ]);

  fenixToolchainRustfmt = (fenixChannelNightly.withComponents [
    "rustfmt"
  ]);

in
{
  # package containing all the Rust/cargo toolchain binaries to import in the dev shells
  toolchain = fenixToolchain;
  # package containing rust-analyzer
  rust-analyzer = pkgs.rust-analyzer;
  # package containing rustfmt (by default nightly rustfmt, as it supports lots of handy directives)
  rustfmt = fenixToolchainRustfmt;

  # craneLib from `crane` package - for building Rust packages with Nix
  craneLib = crane.lib.${system}.overrideToolchain self.toolchain;

  # common args for crane, used for building internal Rust binaries
  # not meant to be modifed as part of downstream customizations
  cranePrivateCommonArgs = {
    pname = "flakebox";

    src = builtins.path {
      name = "flakebox";
      path = ../.;
    };

    nativeBuildInputs = [ pkgs.mold ];

    installCargoArtifactsMode = "use-zstd";
  };

  # flakebox files available to `flakebox` tool
  share = ../share;

  # wrapper over `mkShell` setting up flakebox env
  mkDevShell = callPackage ./mkDevShell.nix { };

  flakeboxBin = callPackage ./flakeboxBin.nix { };
})
