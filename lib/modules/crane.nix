{
  lib,
  config,
  crane,
  fenix,
  ...
}:

let
  inherit (lib) types mkOption;
in
{
  options.craneMkLib = mkOption {
    type = types.attrs;
    description = ''
      craneLib to use by default

      Default value is craneLib initialized with `config.toolchain.channel` toolchain with `config.toolchain.components`
    '';
    default =
      pkgs:
      (crane.mkLib pkgs).overrideToolchain (
        fenix.packages.${pkgs.system}.${config.toolchain.channel}.withComponents config.toolchain.components
      );
  };
}
