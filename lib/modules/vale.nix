{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) types;
  singleLineString = types.addCheck types.str (
    value: !(lib.hasInfix "\r" value || lib.hasInfix "\n" value)
  );
  nonEmptySingleLineString = types.addCheck singleLineString (value: value != "");
  configFileArg = lib.escapeShellArg config.vale.configFile;
  preCommitArgs = lib.escapeShellArgs config.vale.pre-commit.args;
in
{
  options.vale = {
    enable = lib.mkEnableOption "Vale integration" // {
      default = true;
    };

    package = lib.mkOption {
      type = types.package;
      default = pkgs.vale;
      defaultText = lib.literalExpression "pkgs.vale";
      description = "Vale package to add to flakebox development shells.";
    };

    configFile = lib.mkOption {
      type = nonEmptySingleLineString;
      default = ".vale.ini";
      description = "Non-empty single-line path to the Vale configuration, relative to the repository root.";
    };

    just.enable = lib.mkEnableOption "Vale just recipe" // {
      default = true;
    };

    pre-commit = {
      enable = lib.mkEnableOption "Vale git pre-commit hook" // {
        default = true;
      };

      args = lib.mkOption {
        type = types.listOf singleLineString;
        default = [ ];
        description = "Additional single-line arguments passed to Vale by the pre-commit hook.";
      };
    };
  };

  config = lib.mkIf config.vale.enable (
    lib.mkMerge [
      {
        env.shellPackages = [ config.vale.package ];
      }

      (lib.mkIf config.vale.just.enable {
        just.rules.vale = {
          content = ''
            # lint prose with Vale
            [positional-arguments]
            vale *ARGS="":
              vale --config ${configFileArg} . "$@"
          '';
        };
      })

      (lib.mkIf config.vale.pre-commit.enable {
        git.pre-commit.hooks.vale = ''
          if [ ! -s ${configFileArg} ]; then
            return 0
          fi

          vale --config ${configFileArg} . ${preCommitArgs}
        '';
      })
    ]
  );
}
