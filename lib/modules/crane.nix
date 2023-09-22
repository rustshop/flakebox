{ lib, config, pkgs, crane, ... }:

let
  system = pkgs.system;
  inherit (lib) types mkOption;
in
{

  options.craneLib = {
    default = mkOption {
      type = types.attrs;
      description = ''
        craneLib to use by default
        
        Default value is craneLib initialized with `config.toolchain.default` 
      '';
      default = crane.lib.${system}.overrideToolchain config.toolchain.default;
      defaultText = ''
        crane.lib.${system}.overrideToolchain config.toolchain.default
      '';
    };

    nightly = mkOption {
      type = types.attrs;
      description = ''
        craneLib to use when nightly toolchain is needed
        
        Default value is craneLib initialized with `config.toolchain.nightly` 
      '';
      default = crane.lib.${system}.overrideToolchain config.toolchain.nightly;
      defaultText = ''
        crane.lib.${system}.overrideToolchain config.toolchain.nightly
      '';
    };

    stable = mkOption {
      type = types.attrs;
      description = ''
        craneLib to use when stable toolchain is needed
        
        Default value is craneLib initialized with `config.toolchain.stable` 
      '';
      default = crane.lib.${system}.overrideToolchain config.toolchain.stable;
      defaultText = ''
        crane.lib.${system}.overrideToolchain config.toolchain.stable
      '';
    };
  };
}
