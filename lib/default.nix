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
  rust-analyzer = pkgs.rust-analyzer;
  rustfmt = fenixToolchainRustfmt;

  toolchain = fenixToolchain;
  craneLib = crane.lib.${system}.overrideToolchain self.toolchain;

  mkDevShell = callPackage ./mkDevShell.nix { };
})
