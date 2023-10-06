{ pkgs, lib, config, ... }:

let
  inherit (lib) types;
in
{

  options.git = {
    pre-commit = {
      enable = lib.mkEnableOption (lib.mdDoc "git pre-commit hook") // {
        default = true;
      };

      trailing_newline = lib.mkEnableOption (lib.mdDoc "git pre-commit trailing newline check ") // {
        default = true;
      };

      trailing_whitespace = lib.mkEnableOption (lib.mdDoc "git pre-commit trailing whitespace check ") // {
        default = true;
      };

      hooks = lib.mkOption {
        type = types.attrsOf (types.nullOr (types.either types.str types.path));
        description = lib.mdDoc "Attrset of hooks to to execute during git pre-commit hook";
        default = { };
        apply = value: lib.filterAttrs (n: v: v != null) value;
      };
    };
    commit-msg = {
      enable = lib.mkEnableOption (lib.mdDoc "git pre-commit hook") // {
        default = true;
      };

      hooks = lib.mkOption {
        type = types.attrsOf (types.nullOr (types.either types.str types.path));
        description = lib.mdDoc "Attrset of hooks to to execute during git commit-msg hook";
        default = { };
        apply = value: lib.filterAttrs (n: v: v != null) value;
      };
    };

    commit-template = {
      enable = lib.mkEnableOption (lib.mdDoc "git commit message template") // {
        default = true;
      };

      head = lib.mkOption {
        type = types.either types.str types.path;
        description = lib.mdDoc "The head of the template content";
        default = "";
      };

      body = lib.mkOption {
        type = types.either types.str types.path;
        description = lib.mdDoc "The body of the template content";
        default = ''
          # Explain *why* this change is being made                width limit ->|
        '';
      };
    };
  };

  config = lib.mkMerge [

    (lib.mkIf config.git.pre-commit.trailing_whitespace {
      git.pre-commit.hooks.trailing_whitespace = ''
        if ! git diff --check HEAD ; then
          echo "Trailing whitespace detected. Please remove them before committing."
          return 1
        fi
      '';
    })

    (lib.mkIf config.git.pre-commit.trailing_newline {
      git.pre-commit.hooks.trailing_newline = ''
        errors=""
        for path in $(echo "$FLAKEBOX_GIT_LS_TEXT"); do

          # extra branches for clarity
          if [ ! -s "$path" ]; then
             # echo "$path is empty"
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


    (lib.mkIf config.git.commit-msg.enable {
      rootDir."misc/git-hooks/commit-msg" =
        let
          content =
            (lib.removeSuffix "\n" (builtins.concatStringsSep "\n\n"
              (lib.mapAttrsToList
                (rawName: value: value)
                config.git.commit-msg.hooks)));
        in
        {
          # Note: using `writeScript` instead of `writeShellScript` as we want the current-env `bash`
          # not a hardcoded one, as we copy these files into the repo
          source = pkgs.writeScript "commit-msg" ''
            #!/usr/bin/env bash
            ${content}
          ''
          ;
        };


      env.shellHooks = [
        ''
          root="$(git rev-parse --show-toplevel)"
          dot_git="$(git rev-parse --git-common-dir)"
          if [[ ! -d "''${dot_git}/hooks" ]]; then mkdir -p "''${dot_git}/hooks"; fi
          # fix old bug
          rm -f "''${dot_git}/hooks/comit-msg"
          rm -f "''${dot_git}/hooks/commit-msg"
          ln -sf "''${root}/misc/git-hooks/commit-msg" "''${dot_git}/hooks/commit-msg"
        ''
      ];


    })

    (lib.mkIf config.git.commit-msg.enable {
      rootDir."misc/git-hooks/pre-commit" =
        let
          indentString = str: numSpaces:
            let
              spaces = lib.strings.fixedWidthString numSpaces " " "";
              lines = lib.strings.splitString "\n" str;
              indentedLines = builtins.map (line: if line == "" then "" else spaces + line) lines;
            in
            builtins.concatStringsSep "\n" indentedLines;

          replaceNonAlphaNum = str:
            lib.concatStrings (
              builtins.map (ch: if builtins.match "[a-zA-Z0-9]" ch != null then ch else "_")
                (lib.stringToCharacters str)
            );

          hooksFns = builtins.concatStringsSep "\n" (lib.mapAttrsToList
            (rawName: rawValue:
              let
                name = replaceNonAlphaNum rawName;
                value = indentString rawValue 4;
              in
              ''
                function check_${name}() {
                    set -euo pipefail

                ${value}
                }
                export -f check_${name}
              ''
            )
            config.git.pre-commit.hooks);
          hookNames = builtins.concatStringsSep "\n" (lib.mapAttrsToList
            (rawName: value:
              let name = replaceNonAlphaNum rawName; in
              "    check_${name} \\"
            )
            config.git.pre-commit.hooks);
        in
        {
          # Note: using `writeScript` instead of `writeShellScript` as we want the current-env `bash`
          # not a hardcoded one, as we copy these files into the repo
          source = pkgs.writeScript "pre-commit" ''
            ${builtins.readFile ./git/pre-commit.head.sh}
            ${hooksFns}
            parallel \
              --nonotice \
            ::: \
            ${hookNames}
              check_nothing
          '';
        };


      env.shellHooks = [
        ''
          root="$(git rev-parse --show-toplevel)"
          dot_git="$(git rev-parse --git-common-dir)"
          if [[ ! -d "''${dot_git}/hooks" ]]; then mkdir -p "''${dot_git}/hooks"; fi
          # fix old bug
          rm -f "''${dot_git}/hooks/pre-comit"
          rm -f "''${dot_git}/hooks/pre-commit"
          ln -sf "''${root}/misc/git-hooks/pre-commit" "''${dot_git}/hooks/pre-commit"
        ''
      ];

    })

    (lib.mkIf config.git.commit-template.enable {
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
          git config commit.template misc/git-hooks/commit-template.txt
        ''
      ];

    })

  ];
}
