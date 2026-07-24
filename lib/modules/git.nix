{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (lib) types;
  gitHookCheckTimer = pkgs.callPackage ../pkgs/git-hook-check-timer.nix { };
in
{

  options.git = {
    enable = lib.mkEnableOption "Flakebox Git commit hooks and commit template integration" // {
      default = true;
    };

    pre-commit = {
      enable = lib.mkEnableOption "git pre-commit hook" // {
        default = true;
      };

      trailing_newline = lib.mkEnableOption "git pre-commit trailing newline check" // {
        default = true;
      };

      trailing_whitespace = lib.mkEnableOption "git pre-commit trailing whitespace check" // {
        default = true;
      };

      hooks = lib.mkOption {
        type = types.attrsOf (types.nullOr (types.either types.str types.path));
        description = "Attrset of hooks to to execute during git pre-commit hook";
        default = { };
        apply = value: lib.filterAttrs (n: v: v != null) value;
      };
    };
    commit-msg = {
      enable = lib.mkEnableOption "git pre-commit hook" // {
        default = true;
      };

      hooks = lib.mkOption {
        type = types.attrsOf (types.nullOr (types.either types.str types.path));
        description = "Attrset of hooks to to execute during git commit-msg hook";
        default = { };
        apply = value: lib.filterAttrs (n: v: v != null) value;
      };
    };

    commit-template = {
      enable = lib.mkEnableOption "git commit message template" // {
        default = true;
      };

      head = lib.mkOption {
        type = types.either types.str types.path;
        description = "The head of the template content";
        default = "";
      };

      body = lib.mkOption {
        type = types.either types.str types.path;
        description = "The body of the template content";
        default = ''
          # Explain *why* this change is being made                width limit ->|
        '';
      };
    };
  };

  config = lib.mkMerge [

    (lib.mkIf config.git.pre-commit.trailing_whitespace {
      git.pre-commit.hooks.trailing_whitespace = ''
        rev="HEAD"
        if ! git rev-parse -q 1>/dev/null HEAD 2>/dev/null ; then
          >&2 echo "Warning: no commits yet, checking against --root"
          rev="--root"
        fi
        if ! git diff --check $rev ; then
          >&2 echo "Trailing whitespace detected. Please remove them before committing."
          return 1
        fi
      '';
    })

    (lib.mkIf config.git.pre-commit.trailing_newline {
      git.pre-commit.hooks.trailing_newline = ''
        errors=""
        for path in $(echo "$FLAKEBOX_GIT_LS_TEXT"); do

          # extra branches for clarity
          if [ ! -f "$path" ] || [ ! -s "$path" ]; then
             # echo "$path is not a file or is empty"
             true
          elif [ -z "$(tail -c 1 < "$path")" ]; then
             # echo "$path ends with a newline or with a null byte"
             true
          else
            >&2 echo "$path doesn't end with a newline" 1>&2
            errors="true"
          fi
        done

        if [ -n "$errors" ]; then
          >&2 echo "Fix the problems above or use --no-verify" 1>&2
          return 1
        fi
      '';
    })

    (lib.mkIf (config.git.enable && config.git.commit-msg.enable) {
      rootDir."misc/git-hooks/commit-msg" =
        let
          content = (
            lib.removeSuffix "\n" (
              builtins.concatStringsSep "\n\n" (
                lib.mapAttrsToList (rawName: value: value) config.git.commit-msg.hooks
              )
            )
          );
        in
        {
          # Note: using `writeScript` instead of `writeShellScript` as we want the current-env `bash`
          # not a hardcoded one, as we copy these files into the repo
          source = pkgs.writeScript "commit-msg" ''
            #!/usr/bin/env bash
            if [ "''${FLAKEBOX_SKIP_GIT_HOOKS:-}" = 1 ]; then
              exit 0
            fi

            flakebox_commit_message_path="''${1:-}"
            function flakebox_commit_message_failure_guidance() {
              local hook_status=$?

              if [ "$hook_status" -ne 0 ] &&
                [ -d .git ] &&
                [ "$flakebox_commit_message_path" = ".git/COMMIT_EDITMSG" ] &&
                [ -f .git/COMMIT_EDITMSG ]; then
                >&2 echo "flakebox: commit message checks failed; your message is saved in .git/COMMIT_EDITMSG"
                >&2 echo "flakebox: rerun your original git commit command, replacing any message options with:"
                >&2 echo "-eF .git/COMMIT_EDITMSG"
              fi

              return "$hook_status"
            }
            trap flakebox_commit_message_failure_guidance EXIT

            ${content}
          '';
        };

      env.shellHooks = [
        ''
          root="$(git rev-parse --show-toplevel)"
          dot_git="$(git rev-parse --git-common-dir)"
          if [[ ! -d "''${dot_git}/hooks" ]]; then mkdir -p "''${dot_git}/hooks"; fi
          # fix old bug
          if [[ -e "''${dot_git}/hooks/comit-msg" || -L "''${dot_git}/hooks/comit-msg" ]]; then
            rm -f "''${dot_git}/hooks/comit-msg"
          fi
          hook="''${dot_git}/hooks/commit-msg"
          source="''${root}/misc/git-hooks/commit-msg"
          if [[ ! -e "''${hook}" ]] || ! cmp -s "''${source}" "''${hook}"; then
            rm -f "''${hook}"
            ln -sf "''${source}" "''${hook}"
          fi
        ''
      ];

    })

    (lib.mkIf (config.git.enable && config.git.pre-commit.enable) {
      rootDir."misc/git-hooks/pre-commit" =
        let
          indentString =
            str: numSpaces:
            let
              spaces = lib.strings.fixedWidthString numSpaces " " "";
              lines = lib.strings.splitString "\n" str;
              indentedLines = builtins.map (line: if line == "" then "" else spaces + line) lines;
            in
            builtins.concatStringsSep "\n" indentedLines;

          replaceNonAlphaNum =
            str:
            lib.concatStrings (
              builtins.map (ch: if builtins.match "[a-zA-Z0-9]" ch != null then ch else "_") (
                lib.stringToCharacters str
              )
            );

          hooksFns = builtins.concatStringsSep "\n" (
            lib.mapAttrsToList (
              rawName: rawValue:
              let
                name = replaceNonAlphaNum rawName;
                value = indentString rawValue 4;
              in
              # Note: that weird indentation on value is expected
              ''
                # NOTE: THIS FILE IS AUTO-GENERATED BY FLAKEBOX
                function check_${name}() {
                    set -euo pipefail

                    ${lib.strings.trim value}
                }
                export -f check_${name}
              ''
            ) config.git.pre-commit.hooks
          );
          hookNames = lib.mapAttrsToList (
            rawName: _:
            let
              name = replaceNonAlphaNum rawName;
            in
            "check_${name}"
          ) config.git.pre-commit.hooks;
          runHooks = lib.optionalString (hookNames != [ ]) ''
            function flakebox_run_check() {
              FLAKEBOX_COMPACT_GIT_HOOK_WARNINGS=1 \
                flakebox-git-hook-check-timer "$1"
            }
            export -f flakebox_run_check

            set +e
            exec 9> >(flakebox-git-hook-check-timer --compact-warnings >&2)
            formatter_pid=$!
            parallel \
              --nonotice \
              flakebox_run_check \
            ::: \
                ${builtins.concatStringsSep " \\\n    " hookNames} \
              2>&9 9>&-
            parallel_status=$?
            exec 9>&-
            wait "$formatter_pid"
            set -e
            exit "$parallel_status"
          '';

        in
        {
          # Note: using `writeScript` instead of `writeShellScript` as we want the current-env `bash`
          # not a hardcoded one, as we copy these files into the repo
          source = pkgs.writeScript "pre-commit" ''
            #!/usr/bin/env bash
            #
            # NOTE: THIS FILE IS AUTO-GENERATED BY FLAKEBOX
            #
            if [ "''${FLAKEBOX_SKIP_GIT_HOOKS:-}" = 1 ]; then
              exit 0
            fi

            ${builtins.readFile ./git/pre-commit.body.bash}
            ${hooksFns}
            ${runHooks}
            #
            # NOTE: THIS FILE IS AUTO-GENERATED BY FLAKEBOX
            #
          '';
        };

      env.shellHooks = [
        ''
          root="$(git rev-parse --show-toplevel)"
          dot_git="$(git rev-parse --git-common-dir)"
          if [[ ! -d "''${dot_git}/hooks" ]]; then mkdir -p "''${dot_git}/hooks"; fi
          # fix old bug
          if [[ -e "''${dot_git}/hooks/pre-comit" || -L "''${dot_git}/hooks/pre-comit" ]]; then
            rm -f "''${dot_git}/hooks/pre-comit"
          fi
          hook="''${dot_git}/hooks/pre-commit"
          source="''${root}/misc/git-hooks/pre-commit"
          if [[ ! -e "''${hook}" ]] || ! cmp -s "''${source}" "''${hook}"; then
            rm -f "''${hook}"
            ln -sf "''${source}" "''${hook}"
          fi
        ''
      ];
      env.shellPackages = [ gitHookCheckTimer ];

    })

    (lib.mkIf (config.git.enable && config.git.commit-template.enable) {
      rootDir."misc/git-hooks/commit-template.txt" = {
        source = pkgs.writeText "commit-template" (
          lib.removeSuffix "\n" ''
            ${config.git.commit-template.head}
            ${config.git.commit-template.body}
          ''
        );
      };

      env.shellHooks = [
        ''
          # set template
          if [[ "$(git config --get commit.template || true)" != "misc/git-hooks/commit-template.txt" ]]; then
            git config commit.template misc/git-hooks/commit-template.txt
          fi
        ''
      ];

    })

  ];
}
