{ pkgs, lib, config, ... }:
let
  inherit (lib) types;
in
{
  options.just = {
    enable = lib.mkEnableOption "just integration" // {
      default = true;
    };

    rules = lib.mkOption {
      type = types.attrsOf (types.nullOr (types.either types.str types.path));
      description = ''
        Attrset of section of justfile (possibly with multiple rules)

        Notably the name is used only for config identification (e.g. disabling) and actual
        justfile rule name must be used in the value (content of the file).
      '';
      default = {
        # TODO: this is a huge ball of rules, some of which should be conditional on the
        # respective features
        core = ./just/justfile;
      };
      apply = value: lib.filterAttrs (n: v: v != null) value;
    };
  };


  config = lib.mkIf config.just.enable {
    shareDir."overlay/justfile" = {
      source = pkgs.writeText "flakebox-justfile"
        (builtins.concatStringsSep "\n\n"
          (lib.mapAttrsToList
            (k: v: if builtins.typeOf v == "path" then builtins.readFile v else v)
            config.just.rules));
    };
  };
}
