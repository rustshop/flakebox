{ pkgs }:
let
  inherit (pkgs) lib;
  fs = lib.fileset;

  filesetFromPaths =
    { root, paths }:
    fs.unions (map (lib.path.append root) paths);

  fromFileset =
    {
      root,
      fileset,
      filter ? null,
    }:
    let
      allowed =
        if filter == null then
          null
        else
          fs.fromSource (
            lib.sources.cleanSourceWith {
              src = root;
              inherit filter;
            }
          );
    in
    fs.toSource {
      inherit root;
      fileset = if allowed == null then fileset else fs.intersection fileset allowed;
    };

  fromPaths =
    {
      root,
      paths,
      filter ? null,
    }:
    fromFileset {
      inherit root filter;
      fileset = filesetFromPaths { inherit root paths; };
    };

  fromGlobs =
    {
      root,
      patterns,
      filter ? null,
    }:
    if !(lib.sources ? sourceByGlobs) then
      throw "flakeboxLib.source.fromGlobs requires nixpkgs with lib.sources.sourceByGlobs (26.05 or newer)"
    else if !builtins.isPath root then
      throw "flakeboxLib.source.fromGlobs: root must be a path value"
    else
      let
        source = lib.sources.sourceByGlobs root patterns;
      in
      if filter == null then
        source
      else
        # cleanSourceWith evaluates this filter before the source's glob filter, so
        # rejecting a directory avoids both glob matching and subtree traversal.
        lib.sources.cleanSourceWith {
          src = source;
          inherit filter;
        };
in
{
  inherit
    filesetFromPaths
    fromFileset
    fromGlobs
    fromPaths
    ;

  filters = {
    all =
      filters: path: type:
      lib.all (filter: filter path type) filters;
    any =
      filters: path: type:
      lib.any (filter: filter path type) filters;
    not =
      filter: path: type:
      !(filter path type);
    excludeDirectoriesNamed =
      names: path: type:
      type != "directory" || !(lib.elem (builtins.baseNameOf path) names);
  };
}
