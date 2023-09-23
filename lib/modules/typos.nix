{ lib, config, pkgs, ... }:
{

  options.typos = {
    enable = lib.mkEnableOption "typos integration" // {
      default = true;
    };

    pre-commit = {
      enable = lib.mkEnableOption "typos git pre-commit hook" // {
        default = true;
      };
    };
  };


  config = lib.mkIf config.typos.enable {
    git.pre-commit.hooks = {
      typos = ''
        if ! echo "$git_ls_nonbinary_files" | typos --stdin-paths ; then
          >&2 echo "Typos found: Valid new words can be added to '_typos.toml'"
          return 1
        fi
      '';
    };

    env.shellPackages = lib.optionals (!pkgs.stdenv.isAarch64 && !pkgs.stdenv.isDarwin) [
      pkgs.typos
    ];

    just.rules = {
      typos = {
        content = ''
          # check typos
          [no-exit-message]
          typos *PARAMS:
            #!/usr/bin/env bash
            set -eo pipefail

            git_ls_files="$(git ls-files)"
            git_ls_nonbinary_files="$(echo "$git_ls_files" |  grep -v -E "^db/|\.png\$|\.ods\$")"


            if ! echo "$git_ls_nonbinary_files" | typos {{PARAMS}} --stdin-paths; then
              >&2 echo "Typos found: Valid new words can be added to '_typos.toml'"
              return 1
            fi

          # fix all typos
          [no-exit-message]
          typos-fix-all:
            just typos -w
        '';
      };
    };
  };
}
