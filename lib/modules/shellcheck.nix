{
  lib,
  config,
  pkgs,
  ...
}:
{

  options.shellcheck = {
    enable = lib.mkEnableOption "shellcheck integration" // {
      default = true;
    };

    pre-commit = {
      enable = lib.mkEnableOption "shellcheck git pre-commit hook" // {
        default = true;
      };
    };
  };

  config = lib.mkIf config.shellcheck.enable {
    git.pre-commit.hooks = {
      shellcheck = ''
        while LC_ALL=C IFS= read -r -d "" path; do
          if [[ "$path" == *.sh ]]; then
            printf '%s\0' "$path"
          fi
        done < "$FLAKEBOX_GIT_LS_TEXT_FILE" | xargs -0 -r shellcheck --severity=warning --
      '';
    };

    env.shellPackages = lib.optionals (!pkgs.stdenv.isAarch64 && !pkgs.stdenv.isDarwin) [
      pkgs.shellcheck
    ];
  };
}
