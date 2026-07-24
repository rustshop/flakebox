{ pkgs }:
pkgs.runCommand "ast-grep-rules"
  {
    nativeBuildInputs = [ pkgs.ast-grep ];
    src = pkgs.lib.cleanSource ../.;
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
      ast-grep-fixtures/benches \
      ast-grep-fixtures/examples \
      ast-grep-fixtures/tests \
      ast-grep-fixtures/src
    for path in \
      ast-grep-fixtures/benches/case.rs \
      ast-grep-fixtures/examples/case.rs \
      ast-grep-fixtures/tests/case.rs \
      ast-grep-fixtures/src/check-tests.rs \
      ast-grep-fixtures/src/check_test.rs \
      ast-grep-fixtures/src/check_tests.rs \
      ast-grep-fixtures/src/test_check.rs \
      ast-grep-fixtures/src/tests.rs
    do
      printf 'fn fixture() { value.unwrap(); }\n' > "$path"
      ast-grep scan --error "$path"
    done

    production_fixture=ast-grep-fixtures/src/check.rs
    printf 'fn fixture() { value.unwrap(); }\n' > "$production_fixture"
    if ast-grep scan --error "$production_fixture" > violation.log 2>&1; then
      echo "production unwrap fixture unexpectedly passed" >&2
      exit 1
    fi
    grep -Fq 'unwrap-in-production' violation.log

    touch "$out"
  ''
