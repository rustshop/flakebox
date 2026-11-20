{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.actionlint.enable = lib.mkEnableOption "GitHub Actions workflow checks, including ShellCheck for inline shell scripts, in the pre-commit hook";

  config = lib.mkIf config.actionlint.enable {
    env.shellPackages = [
      pkgs.actionlint
      pkgs.shellcheck
    ];

    git.pre-commit.hooks.actionlint = ''
      local workflows=() path shellcheck_path
      while LC_ALL=C IFS= read -r -d "" path; do
        case "$path" in
          .github/workflows/*/*) ;;
          .github/workflows/*.yaml | .github/workflows/*.yml)
            if [[ -f "$path" ]]; then
              workflows+=("$path")
            fi
            ;;
        esac
      done < "$FLAKEBOX_GIT_LS_TEXT_FILE"

      if (( ''${#workflows[@]} == 0 )); then
        return 0
      fi
      shellcheck_path="$(command -v shellcheck)" || {
        echo "flakebox: actionlint requires shellcheck on PATH" >&2
        return 1
      }
      printf '%s\0' "''${workflows[@]}" |
        xargs -0 actionlint -shellcheck "$shellcheck_path" -pyflakes= --
    '';
  };
}
