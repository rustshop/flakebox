{ lib, config, ... }:
let
  inherit (lib) types;
in
{
  options.env = {
    shellPackages = lib.mkOption {
      type = types.listOf types.package;
      description = ''
        Packages to include in all dev shells
      '';
      default = [ ];
    };

    shellHooks = lib.mkOption {
      type = types.listOf types.str;
      description = ''
        List of init hooks to execute when shell is entered
      '';
      default = [ "" ];
    };

  };

  config = {
    rootDir.".config/flakebox/shellHook.sh" = {
      text = ''
        #!/usr/bin/env bash
      ''
      + builtins.concatStringsSep "\n" config.env.shellHooks;
    };
    rootDir.".config/flakebox/.gitignore" = {
      text = ''
        tmp/
      '';
    };
  };
}
