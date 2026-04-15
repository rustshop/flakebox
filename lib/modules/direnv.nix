{ lib, config, ... }:

{

  options.direnv = {
    enable = lib.mkEnableOption "direnv integration" // {
      default = true;
    };

    helperHint.enable =
      lib.mkEnableOption "shell hint about `DIRENV_LOG_FORMAT=\"\"` for cleaner direnv output"
      // {
        default = true;
      };
  };

  config = lib.mkIf config.direnv.enable {
    env.shellHooks = lib.optionals config.direnv.helperHint.enable [
      ''
        if [[ "$-" == *i* ]] && [[ -t 2 ]] && [ -n "''${DIRENV_IN_ENVRC:-}" ]; then
          # and not set DIRENV_LOG_FORMAT
          if [ -n "''${DIRENV_LOG_FORMAT:-}" ]; then
            >&2 echo "💡 Set 'DIRENV_LOG_FORMAT=\"\"' in your shell environment variables for a cleaner output of direnv"
          fi
        fi
      ''
    ];

    rootDir.".envrc" = {
      text = ''
        use flake
      '';
    };
  };
}
