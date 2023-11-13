{ lib, config, ... }:
let
  inherit (lib) types;
in
{

  options.rust = {
    pre-commit = {
      leftover-dbg.enable = lib.mkEnableOption (lib.mdDoc "leftover `dbg!` check in pre-commit hook") // {
        default = true;
      };
      clippy.enable = lib.mkEnableOption (lib.mdDoc "clippy check in pre-commit hook") // {
        default = false;
      };
    };

    rustfmt = {
      enable = lib.mkEnableOption (lib.mdDoc "generation of .rustfmt.toml") // {
        default = true;
      };

      content = lib.mkOption {
        description = lib.mdDoc "The content of the file";
        type = types.str;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.rust.pre-commit.leftover-dbg.enable {
      git.pre-commit.hooks = {
        leftover_dbg = ''
          errors=""
          for path in $(echo "$FLAKEBOX_GIT_LS_TEXT" | grep '.*\.rs'); do
            if grep 'dbg!(' "$path" > /dev/null; then
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
          flakebox-in-each-cargo-workspace cargo clippy --locked --offline --workspace --all-targets -- --deny warnings --allow deprecated
        '';
      };

    })

    {
      rootDir.".config/flakebox/bin/flakebox-in-each-cargo-workspace" = {
        source = ./rust/flakebox-in-each-cargo-workspace;
        mode = "0555";
      };
    }

    (lib.mkIf config.rust.rustfmt.enable {
      rootDir.".rustfmt.toml" = {
        text = config.rust.rustfmt.content;
      };

      rust.rustfmt.content = lib.mkDefault ''
        group_imports = "StdExternalCrate"
        wrap_comments = true
        format_code_in_doc_comments = true
        imports_granularity = "Module"
      '';
    })

    {
      just.rules.clippy = {
        content = ''
          # run `cargo clippy` on everything
          clippy *ARGS="--locked --offline --workspace --all-targets":
            cargo clippy {{ARGS}} -- --deny warnings --allow deprecated

          # run `cargo clippy --fix` on everything
          clippy-fix *ARGS="--locked --offline --workspace --all-targets":
            cargo clippy {{ARGS}} --fix
        '';
      };
    }
  ];
}
