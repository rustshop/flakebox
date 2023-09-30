{ lib, config, pkgs, ... }:
{

  options.shellcheck = {
    enable = lib.mkEnableOption (lib.mdDoc "shellcheck integration") // {
      default = true;
    };

    pre-commit = {
      enable = lib.mkEnableOption (lib.mdDoc "shellcheck git pre-commit hook") // {
        default = true;
      };
    };
  };


  config = lib.mkIf config.shellcheck.enable {
    git.pre-commit.hooks = {
      shellcheck = ''
        for path in $(echo "$FLAKEBOX_GIT_LS_TEXT" | grep -E '.*\.sh$'); do
          shellcheck --severity=warning "$path"
        done
      '';
    };

    env.shellPackages = lib.optionals (!pkgs.stdenv.isAarch64 && !pkgs.stdenv.isDarwin) [
      pkgs.shellcheck
    ];
  };
}
