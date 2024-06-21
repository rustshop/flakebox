{ pkgs, lib, config, ... }:

let
  inherit (lib) types;
in
{

  options.flakebox = {
    lint = {
      enable = lib.mkEnableOption "the flakebox binary integration" // {
        default = true;
      };
    };
    init = {
      enable = lib.mkEnableOption "the `flakebox init` in dev shells" // {
        default = true;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.flakebox.lint.enable {
      env.shellHooks = [
        ''
          if ! flakebox lint --silent; then
            >&2 echo "ℹ️  Project recommendations detected. Run 'flakebox lint' for more info."
          fi
        ''
      ];
    })
  ];
}
