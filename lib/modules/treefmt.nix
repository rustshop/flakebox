{ lib, config, ... }:
let
  inherit (lib) types;
in
{
  options.treefmt = {
    enable = lib.mkEnableOption "clippy check in pre-commit hook" // {
      default = true;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.treefmt.enable {
      git.pre-commit.hooks = {
        treefmt = ''
          treefmt -q --fail-on-change
        '';
      };
    })
  ];
}
