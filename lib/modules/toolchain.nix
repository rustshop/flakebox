{
  lib,
  config,
  pkgs,
  fenix,
  ...
}:

let
  system = pkgs.system;
  inherit (lib) types mkOption;
in
{

  options.toolchain = {
    components = mkOption {
      type = types.listOf types.str;
      description = ''
        Components to include in the default toolchains
      '';

      default = [
        "rustc"
        "cargo"
        "clippy"
        "rust-analyzer"
        "rust-src"
      ];
    };

    channel = mkOption {
      description = ''
        The channel to source the default toolchain from

        Defaults to the the value of the stable channel.
      '';
      type = types.str;
      default = "stable";
    };

    rustfmt = mkOption {
      type = lib.types.package;
      description = ''
        rustfmt package to use in the shell and lints

        Separate from the toolchain as it's common to want a custom (nightly) version,
        for all the great yet unstable features.

        Defaults to the rustfmt from the nightly channel default profile.
      '';
      default = fenix.packages.${system}.default.withComponents [ "rustfmt" ];
    };
  };

  config = { };
}
