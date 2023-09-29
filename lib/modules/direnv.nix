{ lib, config, ... }:

{

  options.direnv = {
    enable = lib.mkEnableOption (lib.mdDoc "direnv integration") // {
      default = true;
    };
  };

  config = lib.mkIf config.direnv.enable {
    env.shellHooks = [
      ''
        if [ -n "''${DIRENV_IN_ENVRC:-}" ]; then
          # and not set DIRENV_LOG_FORMAT
          if [ -n "''${DIRENV_LOG_FORMAT:-}" ]; then
            >&2 echo "💡 Set 'DIRENV_LOG_FORMAT=\"\"' in your shell environment variables for a cleaner output of direnv"
          fi
        fi
      ''
    ];

    shareDir."overlay/.envrc" = {
      text = ''
        use flake
      '';
    };
  };
}
