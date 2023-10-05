{ lib, config, pkgs, crane, ... }:

let
  system = pkgs.system;
  inherit (lib) types mkOption;
in
{

  options.craneLib = {
    default = mkOption {
      type = types.attrs;
      description = lib.mdDoc ''
        craneLib to use by default
        
        Default value is craneLib initialized with `config.toolchain.default`
      '';
      default = crane.lib.${system}.overrideToolchain config.toolchain.default;
      # FIXME:
      # defaultText = lib.mdDoc ''
      #   `crane.lib.''${system}.overrideToolchain config.toolchain.default`
      # '';
    };

    nightly = mkOption {
      type = types.attrs;
      description = lib.mdDoc ''
        craneLib to use when nightly toolchain is needed
        
        Default value is craneLib initialized with `config.toolchain.nightly`
      '';
      default = crane.lib.${system}.overrideToolchain config.toolchain.nightly;
      # FIXME:
      # defaultText = lib.mdDoc ''
      #   `crane.lib.''${system}.overrideToolchain config.toolchain.nightly`
      # '';
    };

    stable = mkOption {
      type = types.attrs;
      description = lib.mdDoc ''
        craneLib to use when stable toolchain is needed
        
        Default value is craneLib initialized with `config.toolchain.stable`
      '';
      default = crane.lib.${system}.overrideToolchain config.toolchain.stable;
      # FIXME:
      # defaultText = lib.mdDoc ''
      #   `crane.lib.''${system}.overrideToolchain config.toolchain.stable`
      # '';
    };
  };
}
