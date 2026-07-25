{ pkgs, flakeboxLib }:
pkgs.runCommand "ast-grep-rules"
  {
    nativeBuildInputs = [ pkgs.ast-grep ];
    src = pkgs.lib.sources.cleanSourceWith {
      src = ../.;
      filter = flakeboxLib.source.filters.all [
        pkgs.lib.sources.cleanSourceFilter
        (flakeboxLib.source.filters.excludeDirectoriesNamed [ "specs" ])
      ];
    };
  }
  ''
    cp -r "$src" source
    chmod -R u+w source
    cd source

    # Promote the behavioral rules to CI errors while retaining the comparison
    # orientation rule as an interactive style hint.
    ast-grep scan --error --hint=prefer-less-than-comparisons
    ast-grep test

    mkdir -p \
      benches \
      examples \
      tests \
      src
    for path in \
      benches/case.rs \
      examples/case.rs \
      tests/case.rs \
      src/check-tests.rs \
      src/check_test.rs \
      src/check_tests.rs \
      src/test_check.rs \
      src/tests.rs
    do
      printf 'fn fixture() { value.unwrap(); }\n' > "$path"
      ast-grep scan --error "$path"
    done

    production_fixture=src/check.rs
    printf 'fn fixture() { value.unwrap(); }\n' > "$production_fixture"
    if ast-grep scan --error "$production_fixture" > violation.log 2>&1; then
      echo "production unwrap fixture unexpectedly passed" >&2
      exit 1
    fi
    grep -Fq 'unwrap-in-production' violation.log

    touch "$out"
  ''
