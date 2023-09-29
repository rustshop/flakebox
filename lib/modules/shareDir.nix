# heavily "inspired" (aka copy&paste&modify) by https://github.com/NixOS/nixpkgs/blob/449ff3b02f9d4aa15c9224af049d6ac170552554/nixos/modules/system/etc/etc.nix
{ lib, pkgs, config, ... }:
let
  inherit (lib) types mkOption;

  shareDir' = lib.filter (f: f.enable) (lib.attrValues config.shareDir);

  shareDir = pkgs.runCommandLocal "mk-flakebox-share-dir" { } /* sh */ ''
    set -euo pipefail

    makeShareDirEntry() {
      src="$1"
      target="$2"
      mode="$3"

      if [[ "$src" = *'*'* ]]; then
        # If the source name contains '*', perform globbing.
        mkdir -p "$out/$target"
        for fn in $src; do
            if [ "$mode" = "symlink" ]; then
              ln -s "$fn" "$out/$target/"
            else
              cp -rT "$fn" "$out/$target"
              chmod -R "$mode" "$out/$target"
            fi
        done
      else

        mkdir -p "$out/$(dirname "$target")"
        if ! [ -e "$out/$target" ]; then
            if [ "$mode" = "symlink" ]; then
              ln -s "$src" "$out/$target"
            else
              cp -rT "$src" "$out/$target"
              chmod -R "$mode" "$out/$target"
            fi
        else
          echo "duplicate entry $target -> $src"
          if [ "$(readlink "$out/$target")" != "$src" ]; then
            echo "mismatched duplicate entry $(readlink "$out/$target") <-> $src"
            ret=1

            continue
          fi
        fi
      fi
    }

    mkdir -p "$out"
    ${lib.concatMapStringsSep "\n" (shareDirEntry: lib.escapeShellArgs [
      "makeShareDirEntry"
      # Force local source paths to be added to the store
      "${shareDirEntry.source}"
      shareDirEntry.target
      shareDirEntry.mode
    ]) shareDir'}
  '';
in
{

  options = {
    shareDirPackage = mkOption {
      type = types.package;
      description = lib.mdDoc "Derivation containing all shareDir files/symlinks";
    };

    shareDir = mkOption {
      default = { };
      description = lib.mdDoc ''
        Set of files that will be generated as as "Flakebox Share Dir".
      '';

      type = types.attrsOf (types.submodule (
        { name, config, options, ... }:
        {
          options = {

            enable = mkOption {
              type = types.bool;
              default = true;
              description = lib.mdDoc ''
                Whether this share dir file should be generated. This
                option allows specific share dir files to be disabled.
              '';
            };

            target = mkOption {
              type = types.str;
              description = lib.mdDoc ''
                Name of symlink (relative to share dir). Defaults to the attribute name.
              '';
            };

            text = mkOption {
              default = null;
              type = types.nullOr types.lines;
              description = lib.mdDoc "Text of the file.";
            };

            source = mkOption {
              type = types.path;
              description = lib.mdDoc "Path of the source file.";
            };

            mode = mkOption {
              type = types.str;
              default = "symlink";
              description = lib.mdDoc ''
                If set to something else than `symlink`,
                the file is copied instead of symlinked, with the given
                file mode.
              '';
            };
          };

          config = {
            target = lib.mkDefault name;
            source = lib.mkIf (config.text != null) (
              let name' = "flakeroot-share-" + lib.replaceStrings [ "/" ] [ "-" ] name;
              in lib.mkDerivedConfig options.text (pkgs.writeText name')
            );
          };
        }
      ));
      apply = value: lib.filterAttrs (n: v: v.enable == true) value;
    };
  };


  config = {
    shareDirPackage = shareDir;
  };
}
