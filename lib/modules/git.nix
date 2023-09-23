{ pkgs, lib, config, ... }:

let
  inherit (lib) types;
in
{

  options.git = {
    pre-commit = {
      enable = lib.mkEnableOption "git pre-commit hook" // {
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


  config = {
    shareDir."overlay/misc/git-hooks/commit-msg" = lib.mkIf config.git.commit-msg.enable {
      source = pkgs.writeShellScript "commit-msg"
        (builtins.concatStringsSep "\n\n"
          (lib.mapAttrsToList
            (rawName: value: value)
            config.git.commit-msg.hooks));
    };

    shareDir."overlay/misc/git-hooks/pre-commit" =
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
      lib.mkIf config.git.pre-commit.enable
        {
          source = pkgs.writeShellScript "pre-commit" ''
            ${builtins.readFile ./git/pre-commit.head.sh}
            ${hooksFns}
            parallel \
            ::: \
            ${hookNames}
                # newline for the last \ to work
          '';
        };

    shareDir."overlay/misc/git-hooks/commit-template.txt" = lib.mkIf config.git.commit-template.enable {
      source = pkgs.writeText "commit-template"
        ''
          ${config.git.commit-template.head}
          ${config.git.commit-template.body}
        '';
    };

    env.shellHooks = [
      ''
        ${pkgs.git}/bin/git config commit.template misc/git-hooks/commit-template.txt
      ''
    ];

  };
}
