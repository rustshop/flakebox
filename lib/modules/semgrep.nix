{
  lib,
  config,
  pkgs,
  ...
}:
{

  options.semgrep = {
    enable = lib.mkEnableOption "semgrep integration" // {
      default = true;
    };

    pre-commit = {
      enable = lib.mkEnableOption "semgrep git pre-commit hook" // {
        default = true;
      };
    };
  };

  config = lib.mkIf config.semgrep.enable {
    git.pre-commit.hooks = {
      semgrep = ''
        # semgrep is not available on MacOS
        if ! command -v semgrep > /dev/null ; then
          return 0
        fi

        if [ ! -f .config/semgrep.yaml ] ; then
          return 0
        fi

        if [ ! -s .config/semgrep.yaml ] ; then
          return 0
        fi

        env SEMGREP_ENABLE_VERSION_CHECK=0 \
          semgrep -q --error --no-rewrite-rule-ids --config .config/semgrep.yaml
      '';
    };

    env.shellPackages =
      lib.optionals (!pkgs.stdenv.hostPlatform.isAarch64 && !pkgs.stdenv.hostPlatform.isDarwin)
        [
          pkgs.semgrep
        ];

    just.rules = {
      semgrep = {
        content = ''
          # run `semgrep`
          semgrep:
            env SEMGREP_ENABLE_VERSION_CHECK=0 \
              semgrep --error --no-rewrite-rule-ids --config .config/semgrep.yaml
        '';
      };
    };
  };
}
