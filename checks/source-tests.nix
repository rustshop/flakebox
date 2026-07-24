{ pkgs, flakeboxLib }:
let
  inherit (pkgs) lib;
  source = flakeboxLib.source;
  fixture = ./source-fixtures;

  selectedPaths = [
    "Cargo.toml"
    "nested"
    "other"
    "specs"
    "specs2"
  ];
  denySpecs = source.filters.excludeDirectoriesNamed [ "specs" ];

  mkFixtureSource =
    root:
    source.fromPaths {
      inherit root;
      paths = selectedPaths;
      filter = denySpecs;
    };

  baseline = mkFixtureSource (fixture + "/baseline");
  linkedSpecsEdit = mkFixtureSource (fixture + "/excluded-change");
  selectedInputEdit = mkFixtureSource (fixture + "/selected-change");

  buildFiles = source.filesetFromPaths {
    root = fixture + "/baseline";
    paths = [
      "Cargo.toml"
      "nested"
      "nested/keep"
      "Cargo.toml"
    ];
  };
  composed = source.fromFileset {
    root = fixture + "/baseline";
    fileset = lib.fileset.union (lib.fileset.difference buildFiles (
      fixture + "/baseline/nested/specs"
    )) (lib.fileset.maybeMissing (fixture + "/baseline/optional"));
  };

  filtered = source.fromPaths {
    root = fixture + "/baseline";
    paths = selectedPaths;
    filter = source.filters.all [
      denySpecs
      (source.filters.not (path: type: type == "regular" && lib.hasSuffix "value.txt" path))
    ];
  };

  globbed = source.fromGlobs {
    root = fixture + "/baseline";
    patterns = [
      "Cargo.toml"
      "nested/**"
      "specs2/**"
    ];
    filter = denySpecs;
  };
  emptyGlob = source.fromGlobs {
    root = fixture + "/baseline";
    patterns = [ "not-present/**" ];
  };

  fails = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
in
assert lib.assertMsg (
  toString baseline == toString linkedSpecsEdit
) "Linked Specs edits must preserve the build source store path";
assert lib.assertMsg (
  toString baseline != toString selectedInputEdit
) "selected build input edits must alter the build source store path";
assert lib.assertMsg (
  !(source.filters.all [
    (_path: _type: false)
    (_path: _type: throw "all did not short-circuit")
  ] "unused" "regular")
) "source.filters.all must short-circuit";
assert lib.assertMsg (source.filters.any [
  (_path: _type: true)
  (_path: _type: throw "any did not short-circuit")
] "unused" "regular") "source.filters.any must short-circuit";
assert lib.assertMsg (fails (
  source.filesetFromPaths {
    root = fixture + "/baseline";
    paths = [ "" ];
  }
)) "empty subpaths must be rejected";
assert lib.assertMsg (fails (
  source.filesetFromPaths {
    root = fixture + "/baseline";
    paths = [ "../baseline" ];
  }
)) "parent subpaths must be rejected";
assert lib.assertMsg (fails (
  source.filesetFromPaths {
    root = fixture + "/baseline";
    paths = [ "/Cargo.toml" ];
  }
)) "absolute subpaths must be rejected";
assert lib.assertMsg (fails (
  source.fromPaths {
    root = fixture + "/baseline";
    paths = [ "missing" ];
  }
)) "missing selected paths must be rejected";
assert lib.assertMsg (fails (
  source.fromFileset {
    root = fixture + "/baseline";
    fileset = ./mergeArgs-tests.nix;
  }
)) "filesets outside root must be rejected";
pkgs.runCommand "source-tests" { } ''
  test -f ${baseline}/Cargo.toml
  test -f ${baseline}/nested/keep/value.txt
  test -L ${baseline}/nested/manifest-link
  test -f ${baseline}/specs
  test -f ${baseline}/specs2/value.txt
  test ! -e ${baseline}/nested/specs
  test ! -e ${baseline}/other/specs

  test -f ${composed}/Cargo.toml
  test -f ${composed}/nested/keep/value.txt
  test -L ${composed}/nested/manifest-link
  test ! -e ${composed}/nested/specs

  test -f ${filtered}/Cargo.toml
  test ! -e ${filtered}/nested/keep/value.txt
  test ! -e ${filtered}/specs2/value.txt
  test ! -e ${filtered}/nested/specs

  test -f ${globbed}/Cargo.toml
  test -f ${globbed}/nested/keep/value.txt
  test -L ${globbed}/nested/manifest-link
  test -f ${globbed}/specs2/value.txt
  test ! -e ${globbed}/nested/specs

  test -z "$(find ${emptyGlob} -mindepth 1 -print -quit)"

  touch $out
''
