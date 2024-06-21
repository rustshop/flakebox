{ lib, config, pkgs, crane, fenix, ... }:

let
  system = pkgs.system;
  inherit (lib) types mkOption;
in
{
  options.craneLib = mkOption {
    type = types.attrs;
    description = ''
      craneLib to use by default

      Default value is craneLib initialized with `config.toolchain.channel` toolchain with `config.toolchain.components`
    '';
    default = (crane.mkLib pkgs).overrideToolchain (fenix.packages.${system}.${config.toolchain.channel}.withComponents config.toolchain.components);
  };
}
