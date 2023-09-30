{ pkgs, lib, config, ... }:
let
  inherit (lib) types;
in
{
  options.just = {
    enable = lib.mkEnableOption (lib.mdDoc "just integration") // {
      default = true;
    };

    rules = lib.mkOption {
      type = types.attrsOf (types.submodule
        ({ config, options, ... }: {
          options = {
            enable = lib.mkOption {
              type = types.bool;
              default = true;
              description = lib.mdDoc ''
                Whether this rule should be generated. This
                option allows specific rules to be disabled.
              '';
            };

            content = lib.mkOption {
              type = types.either types.str types.path;
              default = 1000;
              description = lib.mdDoc ''
                Order of this rule in relation to the others ones.
                The semantics are the same as with `lib.mkOrder`. Smaller values have
                a greater priority.
              '';
            };

            priority = lib.mkOption {
              type = types.int;
              default = 1000;
              description = lib.mdDoc ''
                Order of this rule in relation to the others ones.
                The semantics are the same as with `lib.mkOrder`. Smaller values have
                a greater priority.
              '';
            };
          };
        }));

      description = lib.mdDoc ''
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
        core = {
          priority = 10;
          content = ./just/justfile;
        };
      };

      env.shellHooks = lib.mkAfter [
        ''
          >&2 echo "💡 Run 'just' for a list of available 'just ...' helper recipes"
        ''
      ];

      rootDir."justfile" = {
        source = pkgs.writeText "flakebox-justfile"
          (builtins.concatStringsSep "\n\n"
            (builtins.map (v: v.content)
              (lib.sort (a: b: if a.priority == b.priority then (a.k < b.k) else a.priority < b.priority)
                (lib.mapAttrsToList
                  (k: v: {
                    inherit k;
                    priority = v.priority;
                    content = pathDeref v.content;
                  })
                  config.just.rules))));
      };
    };
}

