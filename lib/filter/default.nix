{ pkgs }:
let
  lib = pkgs.lib;
  cleanSourceWith = lib.cleanSourceWith;

  cleanSourceWithRel =
    {
      root,
      filter,
      trace ? false,
    }:
    let
      baseStr = builtins.toString root;
    in
    lib.cleanSourceWith {
      src = root;
      filter =
        path: type:
        let
          relPath = lib.removePrefix baseStr (toString path);
          include = filter relPath type;
        in
        if trace then
          (builtins.trace "${root}/${relPath}: ${lib.boolToString include}" include)
        else
          include;
    };

  # Filter `root` path, retaining only paths matching/included in elements of `paths`
  # while correctly handling deeply nested `paths`.
  filterSubPaths =
    {
      root,
      paths,
      trace ? false,
    }:
    cleanSourceWithRel {
      inherit root trace;
      filter = (
        relPath: type:
        let
          # since `/` can't appear in path elements, we can use it as a terminator to avoid
          # elements that are just prefix matching full element filter
          relPathTerm = relPath + "/";

          isPrefix = builtins.any (dir: lib.hasPrefix relPathTerm ("/" + dir + "/")) paths;
          isPrefixed = builtins.any (dir: lib.hasPrefix ("/" + dir + "/") relPathTerm) paths;
        in
        if type == "directory" then isPrefix || isPrefixed else isPrefixed
      );
    };

  filterSubdirs =
    {
      root,
      dirs,
      trace ? false,
    }:
    lib.warn
      "`flakeboxLib.filter.filterSubdirs` is now `flakeboxLib.filterSubPaths` and argument `dirs` was renamed to `paths`"
      filterSubPaths
      {
        inherit root trace;
        paths = dirs;
      };
in
{
  inherit
    cleanSourceWith
    cleanSourceWithRel
    filterSubdirs
    filterSubPaths
    ;
}
