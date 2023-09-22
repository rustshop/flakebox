{ pkgs, lib, config, ... }:
let
  inherit (lib) types;
in
{
  options.env = {
    packages = lib.mkOption {
      type = types.listOf types.package;
      description = ''
        TODO: Not implemented yet

        Packages to include in all dev shells and derivations

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
}
