{ lib, config, ... }:

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
      };
    };
  };


  config = {
    shareDir."misc/git-hooks/pre-commit" =
      let
        replaceNonAlphaNum = str: lib.replaceChars
          (builtins.filter
            (c: builtins.stringLength c == 1 && ! (builtins.match "[a-zA-Z0-9]" c != null))
            (builtins.stringToChars str))
          (lib.genList (n: "_") (builtins.stringLength str));

        hooksFns = builtins.concatStringsSep "\n" (lib.mapAttrsToList
          (rawName: value:
            let name = replaceNonAlphaNum rawName; in
            ''
              function check_${name}() {
                set -euo pipefail

                ${value}
              }
              export -f check_${name}
            ''
          )
          config.git.pre-commit.hooks);
        hookNames = builtins.concatStringsSep " " (lib.mapAttrsToList
          (rawName: value:
            let name = replaceNonAlphaNum rawName; in
            "check_${name}"
          )
          config.git.pre-commit.hooks);
      in
      lib.mkIf config.git.pre-commit.enable
        {
          text = ''
            ${builtins.readFile ./git/pre-commit.head.sh}
            ${hooksFns}
            parallel ::: \
              ${hookNames}
          '';
        };

  };
}
