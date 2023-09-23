alias b := build
alias c := check
alias t := test


default:
  @just --list

# run and restart on changes
watch:
  env RUST_LOG=${RUST_LOG:-debug} cargo watch -x run
  
# run `cargo build` on everything
build:
  cargo build --workspace --all-targets

# run `cargo check` on everything
check:
  cargo check --workspace --all-targets

# run tests
test: build
  cargo test

# run lints (git pre-commit hook)
lint:
  env NO_STASH=true $(git rev-parse --git-common-dir)/hooks/pre-commit

# run all checks recommended before opening a PR
final-check: lint
  cargo test --doc
  just test

# run code formatters
format:
  cargo fmt --all
  nixpkgs-fmt $(echo **.nix)


# run `cargo clippy` on everything
clippy:
  cargo clippy --workspace --all-targets -- --deny warnings --allow deprecated

# run `cargo clippy --fix` on everything
clippy-fix:
  cargo clippy --workspace --all-targets --fix


# run `semgrep`
semgrep:
  env SEMGREP_ENABLE_VERSION_CHECK=0 \
    semgrep --error --config .config/semgrep.yaml


# check typos
[no-exit-message]
typos *PARAMS:
  #!/usr/bin/env bash
  set -eo pipefail

  git_ls_files="$(git ls-files)"
  git_ls_nonbinary_files="$(echo "$git_ls_files" |  grep -v -E "^db/|\.png\$|\.ods\$")"


  if ! echo "$git_ls_nonbinary_files" | typos {{PARAMS}} --stdin-paths; then
    >&2 echo "Typos found: Valid new words can be added to '_typos.toml'"
    return 1
  fi

# fix all typos
[no-exit-message]
typos-fix-all:
  just typos -w
