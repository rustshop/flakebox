{ lib, config, ... }:
let
  inherit (lib) types;
in
{
  options.linker = {
    wild = {
      enable = lib.mkEnableOption "wild linker support" // {
        default = true;
      };
    };
    mold = {
      enable = lib.mkEnableOption "mold linker support" // {
        default = true;
      };
    };
  };
}
