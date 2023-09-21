{ pkgs
}:
let
  lib = pkgs.lib;
  cleanSourceWith = lib.cleanSourceWith;

  cleanSourceWithRel = { root, filter }:
    let
      baseStr = builtins.toString root;
    in
    lib.cleanSourceWith {
      src = root;
      filter = path: type:
        let
          relPath = lib.removePrefix baseStr (toString path);
        in
        filter relPath type;
    };

  filterSubdirs =
    { root, dirs }:
    cleanSourceWithRel {
      inherit root;
      filter = (relPath: type:
        let
          includePath = builtins.any
            (dir: lib.hasPrefix ("/" + dir) relPath)
            dirs;
        in
        # uncomment to debug:
          # builtins.trace "${relPath}: ${lib.boolToString includePath}"
        includePath
      );
    };
in
{
  inherit cleanSourceWith cleanSourceWithRel filterSubdirs;
}
