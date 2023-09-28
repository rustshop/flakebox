{ pkgs }:
let
  lib = pkgs.lib;
  cleanSourceWith = lib.cleanSourceWith;

  cleanSourceWithRel = { root, filter, trace ? false }:
    let
      baseStr = builtins.toString root;
    in
    lib.cleanSourceWith {
      src = root;
      filter = path: type:
        let
          relPath = lib.removePrefix baseStr (toString path);
          include = filter relPath type;
        in
        if trace then
          (builtins.trace "${root}/${relPath}: ${lib.boolToString include}" include)
        else
          include;
    };

  filterSubdirs =
    { root, dirs, trace ? false }:
    cleanSourceWithRel {
      inherit root trace;
      filter = (relPath: type:
        builtins.any
          (dir: lib.hasPrefix ("/" + dir) relPath)
          dirs
      );
    };
in
{
  inherit cleanSourceWith cleanSourceWithRel filterSubdirs;
}
