{ lib, config, ... }:
{

  options.rust = {
    pre-commit = {
      leftover-dbg.enable = lib.mkEnableOption "leftover `dbg!` check in pre-commit hook" // {
        default = true;
      };
      clippy.enable = lib.mkEnableOption "clippy check in pre-commit hook" // {
        default = true;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.rust.pre-commit.leftover-dbg.enable {
      git.pre-commit.hooks = {
        leftover_dbg = ''
          errors=""
          for path in $(echo "$git_ls_nonbinary_files" | grep  '.*\.rs'); do
            if grep 'dbg!(' "$path"  > /dev/null; then
              >&2 echo "$path contains dbg! macro"
              errors="true"
            fi
          done

          if [ -n "$errors" ]; then
            >&2 echo "Fix the problems above or use --no-verify" 1>&2
            return 1
          fi
        '';
      };
    })

    (lib.mkIf config.rust.pre-commit.clippy.enable {
      git.pre-commit.hooks = {
        clippy = ''
          cargo clippy --workspace --all-targets -- --deny warnings --allow deprecated
        '';
      };

    })

    {
      just.rules.clippy = {
        content = ''
          # run `cargo clippy` on everything
          clippy:
            cargo clippy --workspace --all-targets -- --deny warnings --allow deprecated

          # run `cargo clippy --fix` on everything
          clippy-fix:
            cargo clippy --workspace --all-targets --fix
        '';
      };
    }
  ];
}
