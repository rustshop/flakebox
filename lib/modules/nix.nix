{ lib, config, ... }:
let
  inherit (lib) types;
in
{

  options.nix = {
    nixfmt = {
      enable = lib.mkEnableOption "nixfmt support" // {
        default = true;
      };

      pre-commit = {
        enable = lib.mkEnableOption "check nixfmt in pre-commit hook" // {
          default = true;
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (config.nix.nixfmt.enable && config.nix.nixfmt.pre-commit.enable) {
      git.pre-commit.hooks = {
        nixfmt = ''
          # we actually rely on word splitting here
          # shellcheck disable=SC2046
          nixfmt -c $(echo "$FLAKEBOX_GIT_LS_TEXT" | grep "\.nix$")
        '';
      };
    })
  ];
}
