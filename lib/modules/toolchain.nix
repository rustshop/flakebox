{ lib, config, pkgs, fenix, ... }:

let
  system = pkgs.system;
  inherit (lib) types mkOption;
in
{

  options.toolchain =
    {

      components = mkOption {
        type = types.listOf types.str;
        description = lib.mdDoc ''
          Components to include in the default toolchains
        '';

        default = [
          "rustc"
          "cargo"
          "clippy"
          "rust-analysis"
          "rust-src"
        ];
      };

      channel = {
        default = mkOption {
          description = lib.mdDoc ''
            The channel to source the default toolchain from

            Defaults to the the value of the stable channel.
          '';
          type = types.str;
          default = config.toolchain.channel.stable;
        };

        stable = mkOption {
          description = lib.mdDoc "The channel to source the stable toolchain from";
          type = types.str;
          default = "stable";
        };

        nightly = mkOption {
          description = lib.mdDoc ''
            The channel to source the nightly toolchain from
          '';
          type = types.str;
          default = "complete";
        };
      };

      default = mkOption {
        type = lib.types.package;
        description = lib.mdDoc "Default toolchain to use";
        default = fenix.packages.${system}.${config.toolchain.channel.default}.withComponents config.toolchain.components;
      };

      stable = mkOption {
        type = lib.types.package;
        description = lib.mdDoc ''
          Stable channel toolchain

          Toolchain to use in situations that require stable toolchain.
        '';
        default =
          fenix.packages.${system}.${config.toolchain.channel.stable}.withComponents config.toolchain.components;
      };

      nightly = mkOption {
        type = lib.types.package;
        description = lib.mdDoc "Nightly channel toolchain";
        default =
          fenix.packages.${system}.${config.toolchain.channel.nightly}.withComponents config.toolchain.components;
      };


      rustfmt = mkOption {
        type = lib.types.package;
        description = lib.mdDoc ''
          rustfmt package to use in the shell and lints

          Separate from the toolchain as it's common to want a custom (nightly) version,
          for all the great yet unstable features.

          Defaults to the rustfmt from the nightly channel.
        '';
        default = fenix.packages.${system}.${config.toolchain.channel.nightly}.withComponents [ "rustfmt" ];
      };

      rust-analyzer = mkOption {
        type = lib.types.package;
        description = lib.mdDoc ''
          rust-analyzer package to use in the shell and lints

          Separate from the toolchain as it's common to want a custom version.

          Defaults to the standard rust-analyzer from nixpkgs input.
        '';
        default = pkgs.rust-analyzer;
      };
    };

  config = { };
}
