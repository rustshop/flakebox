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
        shellcheck_paths=()
        while IFS= read -r path; do
          if [[ "$path" == *.sh ]]; then
            shellcheck_paths+=("$path")
          fi
        done <<< "$FLAKEBOX_GIT_LS_TEXT"

        if [[ "''${#shellcheck_paths[@]}" -ne 0 ]]; then
          shellcheck --severity=warning "''${shellcheck_paths[@]}"
        fi
      '';
    };

    env.shellPackages = lib.optionals (!pkgs.stdenv.isAarch64 && !pkgs.stdenv.isDarwin) [
      pkgs.shellcheck
    ];
  };
}
