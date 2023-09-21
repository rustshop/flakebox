{ lib, config, pkgs, fenix, ... }:

let
  system = pkgs.system;

  fenixStableChannel = fenix.packages.${system}.stable;
  fenixNightlyChannel = fenix.packages.${system}.complete;
  fenixStableToolchain = (fenixStableChannel.withComponents [
    "rustc"
    "cargo"
    "clippy"
    "rust-analysis"
    "rust-src"
  ]);

  fenixNightlyToolchain = (fenixNightlyChannel.withComponents [
    "rustc"
    "cargo"
    "clippy"
    "rust-analysis"
    "rust-src"
  ]);
  fenixToolchainRustfmt = (fenixNightlyChannel.withComponents [
    "rustfmt"
  ]);
in
{

  options.toolchain = {
    stable = lib.mkOption {
      type = lib.types.package;
      default = fenixStableToolchain;
    };

    nightly = lib.mkOption {
      type = lib.types.package;
      default = fenixNightlyToolchain;
    };

    default = lib.mkOption {
      type = lib.types.package;
      default = config.toolchain.stable;
    };

    rustfmt = lib.mkOption {
      type = lib.types.package;
      default = fenixToolchainRustfmt;
    };
  };

  config = { };
}
