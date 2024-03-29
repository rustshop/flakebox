{ lib, config, pkgs, crane, fenix, ... }:

let
  system = pkgs.system;
  inherit (lib) types mkOption;
in
{
  options.craneLib = mkOption {
    type = types.attrs;
    description = lib.mdDoc ''
      craneLib to use by default

      Default value is craneLib initialized with `config.toolchain.channel` toolchain with `config.toolchain.components`
    '';
    default = crane.lib.${system}.overrideToolchain (fenix.packages.${system}.${config.toolchain.channel}.withComponents config.toolchain.components);
  };
}
