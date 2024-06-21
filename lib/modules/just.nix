{ pkgs, lib, config, ... }:
let
  inherit (lib) types;
in
{
  options.just = {
    enable = lib.mkEnableOption "just integration" // {
      default = true;
    };

    importPaths = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of files to generate `import ...` statement for (as a strings in `import` Justfile directive)";
    };

    rules = lib.mkOption {
      type = types.attrsOf (types.submodule
        ({ config, options, ... }: {
          options = {
            enable = lib.mkOption {
              type = types.bool;
              default = true;
              description = ''
                Whether this rule should be generated. This
                option allows specific rules to be disabled.
              '';
            };

            content = lib.mkOption {
              type = types.either types.str types.path;
              default = 1000;
              description = ''
                Order of this rule in relation to the others ones.
                The semantics are the same as with `lib.mkOrder`. Smaller values have
                a greater priority.
              '';
            };

            priority = lib.mkOption {
              type = types.int;
              default = 1000;
              description = ''
                Order of this rule in relation to the others ones.
                The semantics are the same as with `lib.mkOrder`. Smaller values have
                a greater priority.
              '';
            };
          };
        }));

      description = ''
        Attrset of section of justfile (possibly with multiple rules)

        Notably the name is used only for config identification (e.g. disabling) and actual
        justfile rule name must be used in the value (content of the file).
      '';
      default = { };
      apply = value: lib.filterAttrs (n: v: v.enable == true) value;
    };
  };


  config =
    let
      pathDeref = pathOrStr: if builtins.typeOf pathOrStr == "path" then builtins.readFile pathOrStr else pathOrStr;
    in
    lib.mkIf config.just.enable {
      just.rules = {
        default-alias = {
          priority = 9;
          content = ''
            alias b := build
            alias c := check
            alias t := test
          '';
        };
        default = {
          priority = 10;
          content = ''
            [private]
            default:
              @just --list
          '';
        };
        watch = {
          priority = 100;
          content = ''
            # run and restart on changes
            watch *ARGS="-x run":
              #!/usr/bin/env bash
              set -euo pipefail
              if [ ! -f Cargo.toml ]; then
                cd {{invocation_directory()}}
              fi
              env RUST_LOG=''${RUST_LOG:-debug} cargo watch {{ARGS}}
          '';
        };
        build = {
          priority = 100;
          content = ''
            # run `cargo build` on everything
            build *ARGS="--workspace --all-targets":
              #!/usr/bin/env bash
              set -euo pipefail
              if [ ! -f Cargo.toml ]; then
                cd {{invocation_directory()}}
              fi
              cargo build {{ARGS}}
          '';
        };
        check = {
          priority = 100;
          content = ''
            # run `cargo check` on everything
            check *ARGS="--workspace --all-targets":
              #!/usr/bin/env bash
              set -euo pipefail
              if [ ! -f Cargo.toml ]; then
                cd {{invocation_directory()}}
              fi
              cargo check {{ARGS}}
          '';
        };

        test = {
          priority = 100;
          content = ''
            # run tests
            test: build
              #!/usr/bin/env bash
              set -euo pipefail
              if [ ! -f Cargo.toml ]; then
                cd {{invocation_directory()}}
              fi
              cargo test
          '';
        };

        lint = {
          priority = 100;
          content = ''
            # run lints (git pre-commit hook)
            lint:
              #!/usr/bin/env bash
              set -euo pipefail
              env NO_STASH=true $(git rev-parse --git-common-dir)/hooks/pre-commit
          '';
        };

        final-check = {
          priority = 100;
          content = ''
            # run all checks recommended before opening a PR
            final-check: lint ${if config.just.rules ? clippy && config.just.rules.clippy.enable then "clippy" else "" }
              #!/usr/bin/env bash
              set -euo pipefail
              if [ ! -f Cargo.toml ]; then
                cd {{invocation_directory()}}
              fi
              cargo test --doc
              just test
          '';
        };

        format = {
          priority = 100;
          content = ''
            # run code formatters
            format:
              #!/usr/bin/env bash
              set -euo pipefail
              if [ ! -f Cargo.toml ]; then
                cd {{invocation_directory()}}
              fi
              cargo fmt --all
              nixpkgs-fmt $(echo **.nix)
          '';
        };
      };

      env.shellHooks = lib.mkAfter [
        ''
          >&2 echo "💡 Run 'just' for a list of available 'just ...' helper recipes"
        ''
      ];

      rootDir."justfile" =
        let
          raw_content = (builtins.concatStringsSep "\n\n"
            (builtins.map (v: v.content)
              (lib.sort (a: b: if a.priority == b.priority then (a.k < b.k) else a.priority < b.priority)
                (lib.mapAttrsToList
                  (k: v: {
                    inherit k;
                    priority = v.priority;
                    content = pathDeref v.content;
                  })
                  config.just.rules))));

          imports_content = builtins.concatStringsSep "\n" (map
            (pathStr: ''
              import "${pathStr}"
            '')
            config.just.importPaths);
        in
        {
          source = pkgs.writeText "flakebox-justfile" ''
            # THIS FILE IS AUTOGENERATED FROM FLAKEBOX CONFIGURATION
            ${imports_content}
            ${raw_content}
            # THIS FILE IS AUTOGENERATED FROM FLAKEBOX CONFIGURATION
          '';
        };
    };
}

