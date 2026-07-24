{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) types;
  configFileArg = lib.escapeShellArg config.ast-grep.configFile;
  preCommitArgs = lib.escapeShellArgs config.ast-grep.pre-commit.args;
in
{
  options.ast-grep = {
    enable = lib.mkEnableOption "ast-grep integration" // {
      default = true;
    };

    package = lib.mkOption {
      type = types.package;
      default = pkgs.ast-grep;
      defaultText = lib.literalExpression "pkgs.ast-grep";
      description = "ast-grep package to add to flakebox development shells.";
    };

    configFile = lib.mkOption {
      type = types.str;
      default = "sgconfig.yml";
      description = "Path to the ast-grep project configuration, relative to the repository root.";
    };

    just.enable = lib.mkEnableOption "ast-grep just recipe" // {
      default = true;
    };

    pre-commit = {
      enable = lib.mkEnableOption "ast-grep git pre-commit hook" // {
        default = true;
      };

      args = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Additional arguments passed to `ast-grep scan` by the pre-commit hook.
          Use severity overrides such as `--error=RULE_ID` to make selected
          findings block commits.
        '';
      };
    };
  };

  config = lib.mkIf config.ast-grep.enable (
    lib.mkMerge [
      {
        env.shellPackages = [ config.ast-grep.package ];
      }

      (lib.mkIf config.ast-grep.just.enable {
        just.rules.ast-grep = {
          content = ''
            # scan the project with ast-grep rules
            ast-grep *ARGS="":
              ast-grep scan --config ${configFileArg} {{ARGS}}
          '';
        };
      })

      (lib.mkIf config.ast-grep.pre-commit.enable {
        git.pre-commit.hooks.ast_grep = ''
          if [ ! -s ${configFileArg} ]; then
            return 0
          fi

          ast-grep scan --config ${configFileArg} ${preCommitArgs}
        '';
      })
    ]
  );
}
