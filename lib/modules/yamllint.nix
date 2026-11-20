{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.yamllint.enable = lib.mkEnableOption "YAML syntax and duplicate-key checks for tracked YAML files in the pre-commit hook";

  config = lib.mkIf config.yamllint.enable {
    env.shellPackages = [ pkgs.yamllint ];

    git.pre-commit.hooks.yamllint = ''
      local path
      while LC_ALL=C IFS= read -r -d "" path; do
        if [[ "$path" == *.yaml || "$path" == *.yml ]] && [[ -f "$path" ]]; then
          printf '%s\0' "$path"
        fi
      done < "$FLAKEBOX_GIT_LS_TEXT_FILE" |
        xargs -0 -r yamllint -d '{rules: {key-duplicates: enable}}' --
    '';
  };
}
